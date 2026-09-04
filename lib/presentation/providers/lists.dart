import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  Future<List<TaskList>?> refresh() async {
    try {
      final List<TaskList> lists =
          await ref.read(taskflowRepositoryProvider).fetchLists();
      if (ref.mounted) state = AsyncData<List<TaskList>>(lists);
      return lists;
    } on Exception {
      // Silent refresh failure: keep the last good snapshot.
      return null;
    }
  }

  Future<void> createList(String name) async {
    await _repo.createList(name);
    await refresh();
  }

  Future<void> renameList(int id, String name) async {
    // Apply the rename locally from the PATCH response IMMEDIATELY, then
    // refresh. Without the local apply, a refresh that fails (e.g. a stale
    // pooled socket on mobile) would leave the OLD name on screen until the
    // app restarts — the "rename only applies after restart" bug.
    final TaskList renamed = await _repo.renameList(id, name);
    final List<TaskList> current = state.value ?? const <TaskList>[];
    if (ref.mounted && current.isNotEmpty) {
      state = AsyncData<List<TaskList>>(<TaskList>[
        for (final TaskList l in current)
          if (l.id == id) renamed else l,
      ]);
    }
    await refresh();
  }

  Future<void> deleteList(int id) async {
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
