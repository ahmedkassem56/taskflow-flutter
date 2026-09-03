import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../config.dart';
import '../../data/models/enums.dart';
import '../../data/models/item_envelope.dart';
import '../../data/models/task_item.dart';
import 'api_client.dart';
import 'lists.dart';
import 'mutation_bus.dart';
import 'poll_policy.dart';
import 'reorder_math.dart';
import 'view_controller.dart';

part 'items.g.dart';

/// App-mode items (DESIGN.md §5): the display list for the current view
/// (All | list), status filter and debounced query.
///
/// * Server-side filtering: every fetch is `GET /api/items` with `list_id`
///   (list view only), `status` (only when ≠ all) and `q` (when non-empty).
/// * View switches (watch on [viewControllerProvider]) rebuild this provider
///   and refetch the new context; status/query changes refetch silently.
/// * Polling (DESIGN.md §5.2): 5s tick, skipped while the page is hidden, a
///   modal is open, a drag is active, a fetch is in flight, or a mutation is
///   running. Auto-disposed when nothing listens (e.g. while the share route
///   shows), so polls never run off-screen.
/// * Staleness guard: every fetch captures `(listId, status, q, mutation
///   gen)`; a response completing after any of those changed is discarded —
///   the newer mutation/fetch wins until its own settle refresh.
/// * Mutations per DESIGN.md §5.3: toggle-done is the only optimistic op;
///   create/edit/delete are awaited then silently refreshed.
@Riverpod()
class ItemsController extends _$ItemsController {
  Timer? _pollTimer;
  Timer? _queryDebounce;
  bool _fetchInFlight = false;
  StatusFilter _status = StatusFilter.all;
  String _query = '';
  int _placeholderSeq = 0;

  /// Placeholders for creates whose POST is still in flight. Every fetch
  /// result is merged with these so no intermediate fetch (lifecycle rebuild,
  /// poll, view switch) can drop the optimistic row before the POST commits —
  /// the race that made Android adds blink out and back in on slow networks.
  final Map<int, TaskItem> _pendingCreates = <int, TaskItem>{};

  @override
  Future<List<TaskItem>> build() async {
    _armTimers();
    ref.onDispose(_disposeTimers);
    final ViewState view = ref.watch(viewControllerProvider);
    if (view.mode == ViewMode.share) {
      // Share page is showing: keep the previous app data, never fetch.
      return state.value ?? const <TaskItem>[];
    }
    // Fresh (re)mount — e.g. after a share visit the lists snapshot may be
    // stale: silently refresh it (skipped while lists are still initializing
    // on the very first boot).
    final bool listsReady = ref.read(listsControllerProvider.notifier).initialized;
    if (listsReady) {
      unawaited(ref.read(listsControllerProvider.notifier).refresh());
    }
    return _fetchForBuild();
  }

  // ---------------------------------------------------------------------------
  // Public API (UI)
  // ---------------------------------------------------------------------------

  /// Sets the status filter and refetches silently (server-side `status`).
  void setStatus(StatusFilter status) {
    if (_status == status) return;
    _status = status;
    unawaited(_refreshSilently());
  }

  /// Sets the search text; the refetch is debounced 300 ms (DESIGN.md §5.1).
  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    _queryDebounce?.cancel();
    _queryDebounce = Timer(queryDebounce, () {
      _queryDebounce = null;
      if (ref.mounted) unawaited(_refreshSilently());
    });
  }

  /// Optimistic toggle (DESIGN.md §5.3): flips the row locally (canonical
  /// re-sort + status-filter drop), PATCHes `done`, merges the envelope
  /// (`item` replacement + `spawned` insertion at pending-top) and settles
  /// with a silent refresh. On error the flip is reverted and the error
  /// rethrown for the UI to toast. Returns the `spawned` occurrence when the
  /// toggle created one.
  Future<TaskItem?> toggleDone(TaskItem item) async {
    final List<TaskItem>? rows = state.value;
    if (rows == null) return null;
    final int index = rows.indexWhere((TaskItem r) => r.id == item.id);
    if (index < 0) return null;
    final List<TaskItem> snapshot = rows;

    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    try {
      // Optimistic local flip (canonical order + status-filter drop).
      _setData(applyToggle(rows, item.id, status: _status));
      final ItemEnvelope envelope = await ref
          .read(taskflowRepositoryProvider)
          .toggleDone(item.id, done: !rows[index].done);
      if (!ref.mounted) return envelope.spawned;
      final ViewState view = ref.read(viewControllerProvider);
      _setData(
        mergeEnvelope(
          state.value ?? const <TaskItem>[],
          envelope,
          listId: _listIdOf(view),
          status: _status,
          q: _query,
        ),
      );
      return envelope.spawned;
    } on Exception {
      // Revert the optimistic flip; the settle refresh below reconciles.
      if (ref.mounted && state.value != null) {
        _setData(snapshot);
      }
      rethrow;
    } finally {
      bus.end();
      if (ref.mounted) {
        await Future.wait<void>(<Future<void>>[
          _refreshSilently(),
          _refreshListsSilently(),
        ]);
      }
    }
  }

  /// Optimistic create (quick-add): the new pending row is inserted at the
  /// top of the pending block immediately (server semantics: new-on-top), the
  /// POST runs, then the placeholder is swapped for the server row. The
  /// settle refresh of items + list counts runs in the background — the UI
  /// must not wait for it (that serial wait made quick-add feel 1-2 s slow).
  /// On error the placeholder is rolled back and the error rethrown.
  Future<void> createItem({
    required int listId,
    required String title,
    String? notes,
    required Priority priority,
    String? dueDate,
    required num quantity,
    required Recurrence recurrence,
    int? recurrenceInterval,
  }) async {
    final ViewState view = ref.read(viewControllerProvider);
    final bool inApp = view.mode == ViewMode.app;
    final int? viewedListId = _listIdOf(view);
    // Only the *display* is gated on the current view; the pending row is
    // tracked regardless so no fetch can lose it (it re-merges whenever the
    // view would show it).
    final bool visibleHere =
        inApp &&
        _query.trim().isEmpty &&
        _status != StatusFilter.done &&
        (viewedListId == null || viewedListId == listId);
    final List<TaskItem>? rows = state.value;
    final int placeholderId = --_placeholderSeq;
    // Begin the mutation BEFORE the optimistic insert.
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    final DateTime now = DateTime.now().toUtc();
    final TaskItem placeholder = TaskItem(
      id: placeholderId,
      listId: listId,
      title: title,
      notes: notes,
      priority: priority,
      dueDate: dueDate,
      quantity: quantity,
      position: -1,
      done: false,
      recurrence: recurrence,
      recurrenceInterval: recurrenceInterval,
      createdAt: now,
      updatedAt: now,
    );
    // Single source of truth: the pending map. The displayed list is ALWAYS
    // derived through _withPendingCreates, so this row is structurally
    // present until the POST resolves or errors — no fetch can drop it.
    _pendingCreates[placeholderId] = placeholder;
    if (visibleHere && rows != null) {
      _setData(<TaskItem>[placeholder, ...rows]);
    } else if (rows != null) {
      _setData(rows);
    }
    var ok = false;
    try {
      final TaskItem created = await ref
          .read(taskflowRepositoryProvider)
          .createItem(
            listId: listId,
            title: title,
            notes: notes,
            priority: priority,
            dueDate: dueDate,
            quantity: quantity,
            recurrence: recurrence,
            recurrenceInterval: recurrenceInterval,
          );
      ok = true;
      _pendingCreates.remove(placeholderId);
      if (ref.mounted && state.value != null) {
        // Swap the placeholder for the server row, keeping its screen slot.
        // _setData re-merges (map now empty) — the server row is already in
        // the passed list, so this is the canonical committed view.
        _setData(state.value!
            .map((TaskItem r) => r.id == placeholderId ? created : r)
            .toList());
      }
    } on Exception {
      _pendingCreates.remove(placeholderId);
      if (ref.mounted && state.value != null) {
        // Rollback: drop the placeholder from the display (map is empty so
        // the merge re-adds nothing).
        _setData(state.value!
            .where((TaskItem r) => r.id != placeholderId)
            .toList());
      }
      rethrow;
    } finally {
      bus.end();
      if (ref.mounted && ok) {
        unawaited(_settleCreate());
      }
    }
  }

  /// Reconcile after an optimistic create without racing an in-flight poll:
  /// retry past `_fetchInFlight` and refresh list counts too.
  Future<void> _settleCreate() async {
    const int maxTries = 5;
    for (int attempt = 0; attempt < maxTries; attempt++) {
      if (!ref.mounted) return;
      if (!_fetchInFlight) break;
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    await Future.wait<void>(<Future<void>>[
      _refreshSilently(),
      _refreshListsSilently(),
    ]);
  }

  /// Non-optimistic full-field update (DESIGN.md §5.3). The draft carries
  /// every editable field; null `notes`/`dueDate`/`recurrenceInterval`
  /// explicitly clear — the merged-state rule requires sending
  /// `recurrence_interval: null` when leaving `custom`.
  Future<void> updateItem(
    int id, {
    required String title,
    String? notes,
    required Priority priority,
    String? dueDate,
    required num quantity,
    required Recurrence recurrence,
    int? recurrenceInterval,
  }) async {
    if (recurrence == Recurrence.custom && recurrenceInterval == null) {
      throw ArgumentError(
        'recurrenceInterval is required when recurrence is custom',
      );
    }
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    var ok = false;
    try {
      await ref.read(taskflowRepositoryProvider).patchItem(
            id,
            <String, dynamic>{
              'title': title,
              'notes': notes,
              'priority': priority.wire,
              'due_date': dueDate,
              'quantity': quantity,
              'recurrence': recurrence.wire,
              'recurrence_interval': recurrenceInterval,
            },
          );
      ok = true;
    } finally {
      bus.end();
      if (ref.mounted && ok) {
        await Future.wait<void>(<Future<void>>[
          _refreshSilently(),
          _refreshListsSilently(),
        ]);
      }
    }
  }

  /// Non-optimistic delete (await + silent refresh).
  Future<void> deleteItem(int id) async {
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    var ok = false;
    try {
      await ref.read(taskflowRepositoryProvider).deleteItem(id);
      ok = true;
    } finally {
      bus.end();
      if (ref.mounted && ok) {
        await Future.wait<void>(<Future<void>>[
          _refreshSilently(),
          _refreshListsSilently(),
        ]);
      }
    }
  }

  /// Arrow move (DESIGN.md §8): optimistic swap inside the item's done-group
  /// + `PATCH {'move': direction}`. At a group boundary this is a no-op.
  /// Errors roll the swap back, settle-refresh and rethrow.
  Future<void> moveItem(TaskItem item, String direction) async {
    if (!_reorderPermitted) return;
    final List<TaskItem>? rows = state.value;
    if (rows == null) return;
    final bool up = switch (direction) {
      'up' => true,
      'down' => false,
      _ => throw ArgumentError('direction must be "up" or "down"'),
    };
    final List<TaskItem>? swapped = swapInGroup(rows, item.id, up: up);
    if (swapped == null) return; // boundary — server would 200 no-op
    final List<TaskItem> snapshot = rows;
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    try {
      _setData(swapped);
      await ref
          .read(taskflowRepositoryProvider)
          .moveItem(item.id, direction: direction);
    } on Exception {
      if (ref.mounted && state.value != null) _setData(snapshot);
      rethrow;
    } finally {
      bus.end();
      if (ref.mounted) await _refreshSilently();
    }
  }

  /// Drag reorder (DESIGN.md §8): maps the ReorderableListView indices to a
  /// server group ordinal (`move_to`), optimistically rebuilds the dragged
  /// row's done-group (other group untouched), and PATCHes. No-op drops
  /// (same slot / boundary clamp onto the current slot) still silent-refresh.
  /// Errors roll the rebuild back and rethrow.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final List<TaskItem>? rows = state.value;
    if (rows == null) return;
    if (!_reorderPermitted) return;
    if (oldIndex < 0 || oldIndex >= rows.length) return;
    final int draggedId = rows[oldIndex].id;
    final int? ordinal = dragTargetOrdinal(
      rows: rows,
      draggedId: draggedId,
      rawNewIndex: newIndex,
    );
    if (ordinal == null) {
      // Nothing to do — still reconcile with server truth (§8).
      await _refreshSilently();
      return;
    }
    final List<TaskItem> snapshot = rows;
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    try {
      _setData(applyOrdinalMove(rows, draggedId, ordinal));
      await ref
          .read(taskflowRepositoryProvider)
          .moveItemTo(draggedId, ordinal: ordinal);
    } on Exception {
      if (ref.mounted && state.value != null) _setData(snapshot);
      rethrow;
    } finally {
      bus.end();
      if (ref.mounted) await _refreshSilently();
    }
  }

  /// Manual silent refresh (pull-to-refresh / retry-after-error handlers).
  Future<void> refresh() => _refreshSilently();

  /// Reorder is permitted only in a single-list app view with no active
  /// query (DESIGN.md §8 — hidden rows break ordinal mapping; the All view
  /// has no cross-list position).
  bool get reorderPermitted => _reorderPermitted;

  bool get _reorderPermitted {
    final ViewState view = ref.read(viewControllerProvider);
    if (view.mode != ViewMode.app) return false;
    if (_query.trim().isNotEmpty) return false;
    return _listIdOf(view) != null;
  }

  /// Test / lifecycle hook: runs one poll tick immediately.
  void pollNow() => _pollTick();

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  int? _listIdOf(ViewState view) {
    return view.view.when<int?>(all: () => null, list: (int id) => id);
  }

  void _armTimers() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollTick());
    _queryDebounce?.cancel();
    _queryDebounce = null;
  }

  void _disposeTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _queryDebounce?.cancel();
    _queryDebounce = null;
  }

  /// Build-path fetch — returns its result so riverpod drives the
  /// AsyncLoading → AsyncData/AsyncError transition. A stale completion (the
  /// mutation generation or fetch context moved on while in flight) returns
  /// the current value instead of clobbering the newer operation.
  Future<List<TaskItem>> _fetchForBuild() async {
    final int gen = ref.read(mutationBusProvider.notifier).gen;
    final ViewState view = ref.read(viewControllerProvider);
    final int? listId = _listIdOf(view);
    final StatusFilter status = _status;
    final String q = _query;
    _fetchInFlight = true;
    try {
      final List<TaskItem> items = await ref
          .read(taskflowRepositoryProvider)
          .fetchItems(listId: listId, status: status, q: q);
      if (ref.mounted && !_contextChanged(listId, status, q, gen)) {
        return _withPendingCreates(items, listId, status, q);
      }
      return state.value ?? const <TaskItem>[];
    } on Exception catch (error) {
      if (!ref.mounted || _contextChanged(listId, status, q, gen)) {
        return state.value ?? const <TaskItem>[];
      }
      Error.throwWithStackTrace(error, StackTrace.current);
    } finally {
      _fetchInFlight = false;
    }
  }

  /// Silent refresh (polls, status/q changes, mutation settles): keeps the
  /// current data on screen until the response lands; errors are swallowed
  /// (old data stays; the next tick retries). The result passes through
  /// [_withPendingCreates] so no intermediate fetch can drop an in-flight
  /// create's placeholder.
  Future<void> _refreshSilently() async {
    if (_fetchInFlight) return;
    _fetchInFlight = true;
    final int gen = ref.read(mutationBusProvider.notifier).gen;
    final ViewState view = ref.read(viewControllerProvider);
    final int? listId = _listIdOf(view);
    final StatusFilter status = _status;
    final String q = _query;
    try {
      final List<TaskItem> items = await ref
          .read(taskflowRepositoryProvider)
          .fetchItems(listId: listId, status: status, q: q);
      if (ref.mounted && !_contextChanged(listId, status, q, gen)) {
        _setData(_withPendingCreates(items, listId, status, q));
      }
    } on Exception {
      // Silent path: keep the last good snapshot.
    } finally {
      _fetchInFlight = false;
    }
  }

  Future<void> _refreshListsSilently() async {
    await ref.read(listsControllerProvider.notifier).refresh();
  }

  bool _contextChanged(int? listId, StatusFilter status, String q, int gen) {
    if (gen != ref.read(mutationBusProvider.notifier).gen) return true;
    if (status != _status) return true;
    if (q != _query) return true;
    final ViewState view = ref.read(viewControllerProvider);
    return listId != _listIdOf(view);
  }

  /// Merges in-flight create placeholders into a fetch result so no fetch can
  /// momentarily drop an uncommitted row. A placeholder belongs when the
  /// fetch's context (list/status/query) would show it; duplicates of the
  /// server row are skipped once the POST commits (the map is emptied then).
  List<TaskItem> _withPendingCreates(
    List<TaskItem> items,
    int? listId,
    StatusFilter status,
    String q,
  ) {
    if (_pendingCreates.isEmpty) return items;
    final List<TaskItem> result = <TaskItem>[...items];
    for (final MapEntry<int, TaskItem> e in _pendingCreates.entries) {
      final TaskItem p = e.value;
      final bool sameList = listId == null || listId == p.listId;
      final bool notFiltered =
          status != StatusFilter.done && q.trim().isEmpty;
      if (!sameList || !notFiltered) continue;
      // Skip if the row already appeared (e.g. the swap wrote the server row
      // into the passed list before the map cleared, or a fetch already
      // returned it) — never duplicate.
      if (result.any((TaskItem r) => r.id == p.id)) continue;
      if (result.any((TaskItem r) => r.listId == p.listId &&
          !r.done &&
          r.id != p.id &&
          r.position < p.position)) {
        // Keep canonical pending ordering (new-on-top): insert before the
        // first pending item.
        final int idx = result.indexWhere(
            (TaskItem r) => !r.done && r.listId == p.listId);
        result.insert(idx < 0 ? 0 : idx, p);
      } else {
        result.insert(0, p);
      }
    }
    return result;
  }

  /// The single funnel for every state write: the displayed list is ALWAYS
  /// server rows ∪ in-flight create placeholders. Optimistic rows live only
  /// in [_pendingCreates]; no fetch or mutation path can write them away
  /// because the merge is re-applied here on every write. The swap/rollback
  /// callers pass the post-resolve list and clear the map first, so the
  /// placeholder naturally disappears exactly then.
  void _setData(List<TaskItem> items) {
    final List<TaskItem> merged = _withPendingCreates(
      items,
      _listIdOf(ref.read(viewControllerProvider)),
      _status,
      _query,
    );
    final List<TaskItem>? current = state.value;
    if (current != null && sameItems(current, merged)) return;
    state = AsyncData<List<TaskItem>>(merged);
  }

  void _pollTick() {
    final ViewController viewController =
        ref.read(viewControllerProvider.notifier);
    final ViewState view = ref.read(viewControllerProvider);
    if (shouldSkipPoll(
      visible: viewController.appVisible && view.mode == ViewMode.app,
      inFlight: _fetchInFlight,
      dialogOpen: viewController.dialogOpen,
      rearrangeActive: viewController.rearrangeActive,
      pointerDown: viewController.pointerDown,
      mutating: ref.read(mutationBusProvider),
    )) {
      return;
    }
    unawaited(_refreshSilently());
  }
}
