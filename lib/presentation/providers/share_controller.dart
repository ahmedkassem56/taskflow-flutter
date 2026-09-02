import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../config.dart';
import '../../data/models/enums.dart';
import '../../data/models/item_envelope.dart';
import '../../data/models/shared_list.dart';
import '../../data/models/task_item.dart';
import 'api_client.dart';
import 'mutation_bus.dart';
import 'poll_policy.dart';
import 'reorder_math.dart';
import 'view_controller.dart';

part 'share_controller.g.dart';

/// Share-mode controller (DESIGN.md §5): loads `GET /api/shared/{token}`
/// (all items — the shared endpoint has no status/q params; the UI filters
/// client-side over `state.items`, which stays the full canonical list).
///
/// * `load(token)` drives the initial fetch and every retry; while no token
///   is loaded the provider stays in AsyncLoading.
/// * The provider is auto-disposed when the share page unmounts (nothing
///   watches it), which also stops its 5s poll — polls only ever run while
///   the share page is on screen (DESIGN.md §5.2).
/// * Toggle-done is optimistic (DESIGN.md §5.3) — flip + canonical re-sort,
///   PATCH, envelope merge (`item` replacement, `spawned` insertion at
///   pending-top), revert on error — create/edit/delete/reorder are awaited
///   then silently refreshed. Writes require `permission == edit`
///   ([canEdit]); read-only tokens get 403s from the server, and this
///   controller refuses local optimistic ops it can't perform.
@Riverpod()
class ShareController extends _$ShareController {
  /// Sentinel for "no token loaded yet": the provider stays AsyncLoading
  /// until [load] is called (the share page always calls it post-frame).
  static final Future<SharedList> _never = Completer<SharedList>().future;

  Timer? _pollTimer;
  bool _fetchInFlight = false;
  String? _token;

  @override
  Future<SharedList> build() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollTick());
    ref.onDispose(_disposeTimers);
    return _never;
  }

  // ---------------------------------------------------------------------------
  // Public API (UI)
  // ---------------------------------------------------------------------------

  /// Loads (or reloads) the shared list for [token]. Initial/retry loads
  /// surface AsyncLoading/AsyncError; later reloads of the same token are
  /// silent.
  Future<void> load(String token) async {
    if (token.isEmpty) return;
    _token = token;
    if (state.value == null || state.hasError) {
      state = const AsyncLoading<SharedList>();
    }
    await _fetch(initial: true);
  }

  /// Manual silent refresh (pull-to-refresh).
  Future<void> refresh() => _fetch(initial: false);

  /// True when the loaded share grants write access.
  bool get canEdit => state.value?.canEdit ?? false;

  /// Reorder is permitted only with an edit token and no active search
  /// (DESIGN.md §8 — the UI hides arrows/drag otherwise; this is the
  /// controller-side guard).
  bool get reorderPermitted => canEdit;

  /// Optimistic toggle (DESIGN.md §5.3). Returns the `spawned` occurrence
  /// when the toggle created one.
  Future<TaskItem?> toggleDone(TaskItem item) async {
    final SharedList? share = state.value;
    if (share == null || !share.canEdit) return null;
    final String token = _token!;
    final List<TaskItem> rows = share.items;
    final int index = rows.indexWhere((TaskItem r) => r.id == item.id);
    if (index < 0) return null;
    final List<TaskItem> snapshot = rows;

    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    try {
      // Optimistic: flip + canonical re-sort. The UI filters client-side, so
      // no status drop here — the raw list stays complete.
      _setItems(applyToggle(rows, item.id, status: StatusFilter.all));
      final ItemEnvelope envelope = await ref
          .read(taskflowRepositoryProvider)
          .toggleSharedDone(token, item.id, done: !rows[index].done);
      if (!ref.mounted) return envelope.spawned;
      _setItems(
        mergeEnvelope(
          state.value?.items ?? const <TaskItem>[],
          envelope,
          listId: null, // share items are all from the one shared list
          status: StatusFilter.all,
          q: '',
        ),
      );
      return envelope.spawned;
    } on Exception {
      if (ref.mounted && state.value != null) {
        _setItems(snapshot);
      }
      rethrow;
    } finally {
      bus.end();
      if (ref.mounted) await _fetch(initial: false);
    }
  }

  /// Non-optimistic create via `/api/shared/{token}/items` (no `list_id`).
  Future<void> createItem({
    required String title,
    String? notes,
    required Priority priority,
    String? dueDate,
    required num quantity,
    required Recurrence recurrence,
    int? recurrenceInterval,
  }) async {
    if (!canEdit) throw StateError('This shared list is read-only.');
    final String token = _token!;
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    var ok = false;
    try {
      await ref.read(taskflowRepositoryProvider).createSharedItem(
            token,
            title: title,
            notes: notes,
            priority: priority,
            dueDate: dueDate,
            quantity: quantity,
            recurrence: recurrence,
            recurrenceInterval: recurrenceInterval,
          );
      ok = true;
    } finally {
      bus.end();
      if (ref.mounted && ok) await _fetch(initial: false);
    }
  }

  /// Non-optimistic full-field update via the shared endpoint. Null clears
  /// are explicit (incl. `recurrence_interval` when leaving `custom`).
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
    if (!canEdit) throw StateError('This shared list is read-only.');
    if (recurrence == Recurrence.custom && recurrenceInterval == null) {
      throw ArgumentError(
        'recurrenceInterval is required when recurrence is custom',
      );
    }
    final String token = _token!;
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    var ok = false;
    try {
      await ref.read(taskflowRepositoryProvider).patchSharedItem(
            token,
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
      if (ref.mounted && ok) await _fetch(initial: false);
    }
  }

  /// Non-optimistic delete via the shared endpoint.
  Future<void> deleteItem(int id) async {
    if (!canEdit) throw StateError('This shared list is read-only.');
    final String token = _token!;
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    var ok = false;
    try {
      await ref.read(taskflowRepositoryProvider).deleteSharedItem(token, id);
      ok = true;
    } finally {
      bus.end();
      if (ref.mounted && ok) await _fetch(initial: false);
    }
  }

  /// Arrow move (DESIGN.md §8) via the shared endpoint.
  Future<void> moveItem(TaskItem item, String direction) async {
    if (!reorderPermitted) return;
    final SharedList? share = state.value;
    if (share == null) return;
    final bool up = switch (direction) {
      'up' => true,
      'down' => false,
      _ => throw ArgumentError('direction must be "up" or "down"'),
    };
    final List<TaskItem>? swapped =
        swapInGroup(share.items, item.id, up: up);
    if (swapped == null) return; // boundary — server would 200 no-op
    final List<TaskItem> snapshot = share.items;
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    try {
      _setItems(swapped);
      await ref
          .read(taskflowRepositoryProvider)
          .moveSharedItem(_token!, item.id, direction: direction);
    } on Exception {
      if (ref.mounted && state.value != null) _setItems(snapshot);
      rethrow;
    } finally {
      bus.end();
      if (ref.mounted) await _fetch(initial: false);
    }
  }

  /// Drag reorder (DESIGN.md §8) via the shared endpoint. Reorderable
  /// indices refer to the UI's (client-filtered) list, which — with an empty
  /// search — is exactly one done-group block of the raw list, so the group
  /// ordinal math applies unchanged.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final SharedList? share = state.value;
    if (share == null) return;
    if (!reorderPermitted) return;
    final List<TaskItem> rows = share.items;
    if (oldIndex < 0 || oldIndex >= rows.length) return;
    final int draggedId = rows[oldIndex].id;
    final int? ordinal = dragTargetOrdinal(
      rows: rows,
      draggedId: draggedId,
      rawNewIndex: newIndex,
    );
    if (ordinal == null) {
      await _fetch(initial: false); // no-op drop — reconcile with the server
      return;
    }
    final List<TaskItem> snapshot = rows;
    final MutationBus bus = ref.read(mutationBusProvider.notifier);
    bus.begin();
    try {
      _setItems(applyOrdinalMove(rows, draggedId, ordinal));
      await ref
          .read(taskflowRepositoryProvider)
          .moveSharedItemTo(_token!, draggedId, ordinal: ordinal);
    } on Exception {
      if (ref.mounted && state.value != null) _setItems(snapshot);
      rethrow;
    } finally {
      bus.end();
      if (ref.mounted) await _fetch(initial: false);
    }
  }

  /// Test / lifecycle hook: runs one poll tick immediately.
  void pollNow() => _pollTick();

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _fetch({required bool initial}) async {
    final String? token = _token;
    if (token == null) return;
    if (_fetchInFlight) return;
    _fetchInFlight = true;
    final int gen = ref.read(mutationBusProvider.notifier).gen;
    try {
      final SharedList share =
          await ref.read(taskflowRepositoryProvider).fetchShared(token);
      if (!ref.mounted) return;
      if (gen != ref.read(mutationBusProvider.notifier).gen) return;
      _setShare(share);
    } on Exception catch (error) {
      if (!ref.mounted) return;
      if (gen != ref.read(mutationBusProvider.notifier).gen) return;
      if (initial) {
        state = AsyncError<SharedList>(error, StackTrace.current);
      }
      // Silent refreshes keep the last good snapshot.
    } finally {
      _fetchInFlight = false;
    }
  }

  void _setShare(SharedList share) {
    state = AsyncData<SharedList>(share);
  }

  void _setItems(List<TaskItem> items) {
    final SharedList? current = state.value;
    if (current == null) {
      return;
    }
    _setShare(current.copyWith(items: items));
  }

  void _disposeTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _pollTick() {
    if (_token == null) return;
    final ViewController viewController =
        ref.read(viewControllerProvider.notifier);
    final ViewState view = ref.read(viewControllerProvider);
    if (shouldSkipPoll(
      visible: viewController.appVisible && view.mode == ViewMode.share,
      inFlight: _fetchInFlight,
      dialogOpen: viewController.dialogOpen,
      rearrangeActive: viewController.rearrangeActive,
      pointerDown: viewController.pointerDown,
      mutating: ref.read(mutationBusProvider),
    )) {
      return;
    }
    unawaited(_fetch(initial: false));
  }
}
