import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/trace_log.dart';
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
  DateTime? _lastMutationEnd;
  /// Ids of items created on THIS controller that must be present in any
  /// applied fetch. A poll whose read snapshot predates a create's commit
  /// returns a list WITHOUT the new id — applying it would make the just-added
  /// row vanish (the trace-proven "appears, disappears, returns at next poll").
  /// A response containing the id (post-commit snapshot) clears the entry; the
  /// entry also expires after [_pendingCreateGuardMs] so a create that the
  /// server later removes can't wedge the list forever.
  final Map<int, DateTime> _pendingCreateGuards = <int, DateTime>{};
  static const Duration _pendingCreateGuardMs = Duration(seconds: 8);

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

  /// Create (app mode): no optimism — the POST is awaited and then a single
  /// authoritative refresh lands the new row (server new-on-top). The
  /// composer clears its field immediately on submit for the rapid-entry
  /// feel; the row appears within one RTT (~50-300ms). Because the row is
  /// never inserted client-side, no poll, snapshot or rebuild can ever make
  /// it flash out of existence — the async-creation race class is gone by
  /// construction.
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
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    // Context at submit time — the insert after the POST only applies if the
    // user is still looking at this same list/filter/query.
    final ViewState view = ref.read(viewControllerProvider);
    final int? ctxListId = _listIdOf(view);
    final StatusFilter ctxStatus = _status;
    final String ctxQ = _query;
    _lastMutationEnd = null;
    bus.begin();
    traceLog.log('create START list=$listId "$title"');
    TaskItem created;
    try {
      created = await ref
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
      traceLog.log('create OK id=${created.id} "$title"');
      // Register the guard BEFORE any subsequent fetch can apply a
      // pre-commit snapshot that lacks this item.
      _pendingCreateGuards[created.id] =
          DateTime.now().add(_pendingCreateGuardMs);
    } finally {
      bus.end();
      _lastMutationEnd = DateTime.now();
    }
    if (!ref.mounted) return;
    // Show the row NOW, straight from the POST's own 201 response — the item
    // is committed server-side and the server already returned it, so no
    // second round-trip (reconcile GET) is needed for it to appear. Guards
    // mirror the fetch staleness rules: insert only when the view context is
    // unchanged and the item would actually be visible here.
    if (ctxQ.isEmpty &&
        ctxStatus != StatusFilter.done &&
        ctxListId == _listIdOf(ref.read(viewControllerProvider)) &&
        ctxStatus == _status &&
        ctxQ == _query) {
      final List<TaskItem> current = state.value ?? const <TaskItem>[];
      if (!current.any((TaskItem e) => e.id == created.id)) {
        traceLog.log('create INSERT id=${created.id} '
            'rows ${current.length}->${current.length + 1}');
        _setData(<TaskItem>[created, ...current]);
      }
    }
    // Background reconcile: server truth for counts, position, neighbors —
    // the row is already visible, so this can never be on the user's path.
    unawaited(_refreshSilently(force: true));
    if (ref.mounted) {
      unawaited(_refreshListsSilently());
    }
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

  /// Non-optimistic delete (await + silent refresh). The settle refresh is
  /// forced so an in-flight 5s poll can't delay the row's removal (the
  /// "deletes after a few seconds" bug — same class as the create delay).
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
          _refreshSilently(force: true),
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
      traceLog.log('buildFetched ${items.length}');
      if (ref.mounted && !_contextChanged(listId, status, q, gen)) {
        final List<TaskItem>? guarded = _dropPreCommitSnapshots(items);
        if (guarded != null) return items;
        traceLog.log('buildFetch DISCARDED pre-commit snapshot');
        return state.value ?? const <TaskItem>[];
      }
      traceLog.log('buildFetch DISCARDED gen/ctx');
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

  /// Silent refresh (polls, status/q changes): keeps the current data on screen
  /// until the response lands; errors are swallowed. When [force] is true the
  /// in-flight guard is bypassed — used by mutation settles (a create must
  /// fetch its committed row NOW, not on the next 5s tick; an in-flight poll
  /// started before the mutation is discarded by the gen guard anyway).
  Future<void> _refreshSilently({bool force = false}) async {
    if (_fetchInFlight && !force) return;
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
        final List<TaskItem>? guarded = _dropPreCommitSnapshots(items);
        if (guarded == null) {
          traceLog.log(
              'fetch DISCARDED ${items.length} (pre-commit snapshot: '
              'missing just-created item)');
          return;
        }
        traceLog.log('fetch OK ${items.length} (gen ok)');
        _setData(items);
      } else {
        traceLog.log('fetch DISCARDED ${items.length} (gen/ctx changed)');
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

  /// Returns [items] if it is NOT a pre-commit snapshot (it contains every
  /// still-guarded just-created id, or none are guarded); otherwise returns
  /// null to signal "discard" (the response predates a create's commit). A
  /// guarded id that IS present clears its guard (server has committed; future
  /// snapshots include it).
  List<TaskItem>? _dropPreCommitSnapshots(List<TaskItem> items) {
    if (_pendingCreateGuards.isEmpty) return items;
    final DateTime now = DateTime.now();
    final Set<int> fetched = items.map((TaskItem e) => e.id).toSet();
    final List<int> missing = <int>[];
    _pendingCreateGuards.removeWhere((int id, DateTime expiry) {
      if (expiry.isBefore(now)) return true; // expired guard
      if (fetched.contains(id)) return true; // committed — clear
      missing.add(id);
      return false;
    });
    return missing.isEmpty ? items : null;
  }

  bool _contextChanged(int? listId, StatusFilter status, String q, int gen) {
    if (gen != ref.read(mutationBusProvider.notifier).gen) return true;
    if (status != _status) return true;
    if (q != _query) return true;
    final ViewState view = ref.read(viewControllerProvider);
    return listId != _listIdOf(view);
  }

  /// Plain state write. No optimistic-create merging (create is
  /// non-optimistic — the row only ever exists in fetched data, so nothing
  /// can make it "blink").
  void _setData(List<TaskItem> items) {
    final List<TaskItem>? current = state.value;
    if (current != null && sameItems(current, items)) {
      traceLog.log('setData no-op (${items.length})');
      return;
    }
    traceLog.log('setData ${current?.length}->${items.length}');
    state = AsyncData<List<TaskItem>>(items);
  }

  /// How long after a mutation ends to suppress poll ticks. A poll that starts
  /// during/just after a mutation can carry a SQLite pre-commit snapshot and
  /// clobber the committed state (the Android add-blink); the settle refresh
  /// is the authority in this window.
  static const Duration _mutationGrace = Duration(milliseconds: 1200);

  void _pollTick() {
    final ViewController viewController =
        ref.read(viewControllerProvider.notifier);
    final ViewState view = ref.read(viewControllerProvider);
    // Suppress polls during the post-mutation grace window.
    if (_lastMutationEnd != null &&
        DateTime.now().difference(_lastMutationEnd!) < _mutationGrace) {
      return;
    }
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
