import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/trace_log.dart';
import '../../data/models/share_link.dart';
import '../../data/models/task_list.dart';
import '../../data/repositories/taskflow_repository.dart';
import 'api_client.dart';

part 'lists.g.dart';

/// App-mode lists (sidebar + counts). `AsyncValue<List<TaskList>>` — initial
/// load goes through [build] (AsyncLoading → data/error); every mutation
/// awaits the server then silently refreshes (DESIGN.md §5.3 — list ops are
/// non-optimistic).
///
/// Deleting a list while it is the current view: the lists refresh below
/// triggers the ViewController (which watches this provider) to notice the
/// vanished list and fall back to All (DESIGN.md §5 view transitions).
@Riverpod(keepAlive: true)
class ListsController extends _$ListsController {
  bool _initialized = false;

  /// Staleness generation: bumped at the start of every mutation and every
  /// refresh. A refresh response is applied ONLY if no newer operation started
  /// while it was in flight — otherwise an older `GET /api/lists` (e.g. one
  /// started before a rename, carrying the pre-rename name) could land AFTER
  /// the rename and revert it on screen (the "rename only applies after
  /// restart" bug, seen on web AND Android — a pure client race).
  int _gen = 0;

  /// True once the first lists fetch succeeded (boot). Item controllers use
  /// this to decide whether a fresh mount should re-sync the lists snapshot.
  bool get initialized => _initialized;

  @override
  Future<List<TaskList>> build() async {
    try {
      final List<TaskList> lists =
          await ref.read(taskflowRepositoryProvider).fetchLists();
      _initialized = true;
      return lists;
    } on Exception {
      _initialized = false;
      rethrow;
    }
  }

  TaskflowRepository get _repo => ref.read(taskflowRepositoryProvider);

  /// Silent authoritative refresh (used after every list mutation and by the
  /// items controller after item mutations, so sidebar counts stay fresh).
  /// Gen-guarded: a response is applied only if no newer operation started
  /// while this fetch was in flight (last-start-wins, not last-arrival).
  Future<List<TaskList>?> refresh() async {
    final int gen = ++_gen;
    try {
      final List<TaskList> lists =
          await ref.read(taskflowRepositoryProvider).fetchLists();
      if (!ref.mounted || gen != _gen) {
        traceLog.log('lists refresh DISCARDED (stale, started before a newer op)');
        return null;
      }
      state = AsyncData<List<TaskList>>(lists);
      return lists;
    } on Exception {
      // Silent refresh failure: keep the last good snapshot.
      return null;
    }
  }

  Future<void> createList(String name) async {
    _gen++; // invalidate any in-flight fetch started before this mutation
    await _repo.createList(name);
    await refresh();
  }

  Future<void> renameList(int id, String name) async {
    // Apply the rename locally from the PATCH response IMMEDIATELY, then
    // refresh. The gen bump at the start invalidates any in-flight lists
    // fetch that predates the rename — without it, such a fetch (carrying the
    // OLD name) could land after the local apply and REVERT the rename on
    // screen until the next app restart.
    _gen++;
    traceLog.log('rename START id=$id name="$name"');
    final TaskList renamed = await _repo.renameList(id, name);
    traceLog.log('rename OK server -> "${renamed.name}"');
    final List<TaskList> current = state.value ?? const <TaskList>[];
    if (ref.mounted && current.isNotEmpty) {
      state = AsyncData<List<TaskList>>(<TaskList>[
        for (final TaskList l in current)
          if (l.id == id) renamed else l,
      ]);
      traceLog.log('rename LOCAL-APPLIED (${current.length} lists)');
    } else {
      traceLog.log('rename local-apply SKIPPED (state empty/!mounted)');
    }
    final List<TaskList>? fresh = await refresh();
    traceLog.log('rename refresh -> ${fresh?.length ?? 'FAILED'} lists');
  }

  Future<void> deleteList(int id) async {
    _gen++; // invalidate any in-flight fetch started before this mutation
    await _repo.deleteList(id);
    await refresh();
  }

  /// `POST /api/lists/{id}/shares` — returns the created link so the share
  /// dialog can display/revoke it (DESIGN.md §5.3, non-optimistic).
  Future<ShareLink> createShare(int listId, String permission) async {
    final ShareLink link =
        await _repo.createShare(listId, permission: permission);
    return link;
  }

  /// `DELETE /api/shares/{token}`.
  Future<void> revokeShare(String token) async {
    await _repo.revokeShare(token);
  }
}
