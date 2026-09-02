import 'package:flutter/foundation.dart';

import '../../data/models/enums.dart';
import '../../data/models/item_envelope.dart';
import '../../data/models/task_item.dart';

/// Pure list-ordering + reorder math shared by the controllers (DESIGN.md
/// §2.1, §8). No network, no state — unit-tested directly.
///
/// Invariants:
/// * Server order is authoritative and always `(done, position, id)`.
/// * The display list is the server array order; these helpers only rebuild
///   it locally for optimistic ops and always match what the server would
///   produce (positions/ids sort ties the same way).

/// Canonical server sort: pending first, then `position`, then `id`
/// (DESIGN.md §2.1 — never sort by priority/due date client-side).
List<TaskItem> sortItems(List<TaskItem> items) {
  final List<TaskItem> copy = List<TaskItem>.of(items);
  copy.sort((TaskItem a, TaskItem b) {
    if (a.done != b.done) return a.done ? 1 : -1;
    if (a.position != b.position) return a.position.compareTo(b.position);
    return a.id.compareTo(b.id);
  });
  return copy;
}

/// True when [item] passes the status filter.
bool matchesStatus(TaskItem item, StatusFilter status) {
  switch (status) {
    case StatusFilter.all:
      return true;
    case StatusFilter.pending:
      return !item.done;
    case StatusFilter.done:
      return item.done;
  }
}

/// Case-insensitive title/notes contains, close to the server's LIKE
/// semantics (DESIGN.md §5.1 share-mode client filter).
bool matchesQuery(TaskItem item, String query) {
  final String needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  if (item.title.toLowerCase().contains(needle)) return true;
  final String? notes = item.notes;
  return notes != null && notes.toLowerCase().contains(needle);
}

/// Client-side status+q filter preserving server order (share mode —
/// DESIGN.md §5.1: the shared endpoint has no status/q params).
List<TaskItem> filterItems(
  List<TaskItem> items, {
  StatusFilter status = StatusFilter.all,
  String q = '',
}) {
  return sortItems(
    items
        .where(
          (TaskItem item) =>
              matchesStatus(item, status) && matchesQuery(item, q),
        )
        .toList(),
  );
}

/// Optimistic toggle (DESIGN.md §5.3): flip `done`, restore canonical
/// `(done, position, id)` order, and drop rows that no longer match the
/// active status filter (parity with the server-side filtered fetch).
/// Returns a new list; the input is untouched.
List<TaskItem> applyToggle(
  List<TaskItem> rows,
  int itemId, {
  required StatusFilter status,
}) {
  final List<TaskItem> flipped = <TaskItem>[
    for (final TaskItem row in rows)
      if (row.id == itemId) row.copyWith(done: !row.done) else row,
  ];
  return sortItems(flipped)
      .where((TaskItem row) => matchesStatus(row, status))
      .toList();
}

/// Merges a PATCH envelope into the current display list after an optimistic
/// toggle (DESIGN.md §5.3):
/// * the envelope `item` replaces the row — unless it no longer matches the
///   active fetch context (list view, status filter, query), in which case
///   it is dropped (the server-side refetch would exclude it too);
/// * a `spawned` occurrence is inserted at the top of the pending block when
///   it would be visible under the same context.
/// Result is re-sorted canonically; the spawned item carries `position 0`,
/// so the sort places it first among pending rows.
List<TaskItem> mergeEnvelope(
  List<TaskItem> rows,
  ItemEnvelope envelope, {
  required int? listId,
  required StatusFilter status,
  required String q,
}) {
  final List<TaskItem> next = <TaskItem>[
    for (final TaskItem row in rows)
      if (row.id != envelope.item.id) row,
  ];
  if (_visibleInContext(envelope.item, listId, status, q)) {
    next.add(envelope.item);
  }
  final TaskItem? spawned = envelope.spawned;
  if (spawned != null && _visibleInContext(spawned, listId, status, q)) {
    next.add(spawned);
  }
  return sortItems(next);
}

bool _visibleInContext(
  TaskItem item,
  int? listId,
  StatusFilter status,
  String q,
) {
  if (listId != null && item.listId != listId) return false;
  if (!matchesStatus(item, status)) return false;
  return matchesQuery(item, q);
}

/// Arrow up/down (DESIGN.md §8): swaps [itemId] with its adjacent row *of the
/// same done-group* in the display list. Returns null when the item is at a
/// group boundary (server would answer a 200 no-op) or not found.
List<TaskItem>? swapInGroup(
  List<TaskItem> rows,
  int itemId, {
  required bool up,
}) {
  final int index = rows.indexWhere((TaskItem r) => r.id == itemId);
  if (index < 0) return null;
  final TaskItem item = rows[index];
  final int groupIndex =
      rows.take(index).where((TaskItem r) => r.done == item.done).length;
  final int groupSize =
      rows.where((TaskItem r) => r.done == item.done).length;
  if (up && groupIndex == 0) return null;
  if (!up && groupIndex == groupSize - 1) return null;
  // Adjacent same-group neighbor in the display list.
  final int neighborIndex = up ? index - 1 : index + 1;
  final List<TaskItem> next = List<TaskItem>.of(rows);
  final TaskItem tmp = next[index];
  next[index] = next[neighborIndex];
  next[neighborIndex] = tmp;
  return next;
}

/// Drag mapping (DESIGN.md §8) — converts a `ReorderableListView.onReorder`
/// `(oldIndex, newIndex)` into the server group ordinal `k` to PATCH with
/// `move_to`, or null when the drop is a no-op.
///
/// Algorithm:
/// 1. `newIndex > oldIndex ⇒ newIndex--` (post-removal index).
/// 2. `g` = display rows with `done == dragged.done` (in order); the dragged
///    row's ordinal in `g` is `oldOrd`.
/// 3. `k` = number of g-rows preceding the post-removal target position.
/// 4. Clamp `k` to `[0, g.length-1]` — the **done-group boundary clamp**:
///    dragging a pending row into the done block clamps to the last pending
///    ordinal (cross-group `move_to` is impossible server-side).
/// 5. `k == oldOrd` ⇒ nothing to do (null).
int? dragTargetOrdinal({
  required List<TaskItem> rows,
  required int draggedId,
  required int rawNewIndex,
}) {
  if (rows.isEmpty) return null;
  final int oldIndex = rows.indexWhere((TaskItem r) => r.id == draggedId);
  if (oldIndex < 0) return null;
  final TaskItem dragged = rows[oldIndex];
  final List<TaskItem> postRemoval = List<TaskItem>.of(rows)
    ..removeAt(oldIndex);
  final int target =
      (rawNewIndex > oldIndex ? rawNewIndex - 1 : rawNewIndex)
          .clamp(0, rows.length - 1);
  if (target == oldIndex) return null;

  final List<TaskItem> group =
      rows.where((TaskItem r) => r.done == dragged.done).toList();
  final int oldOrd = group.indexWhere((TaskItem r) => r.id == draggedId);

  int k = 0;
  for (int i = 0; i < target; i++) {
    if (postRemoval[i].done == dragged.done) k++;
  }
  k = k.clamp(0, group.length - 1);
  return k == oldOrd ? null : k;
}

/// Optimistic rebuild after a drag resolves to ordinal [k] (DESIGN.md §8):
/// remove the dragged row and re-insert it at ordinal [k] of its own
/// done-group; rows of the other group keep their places. Result is a
/// canonical pending-block + done-block list.
List<TaskItem> applyOrdinalMove(
  List<TaskItem> rows,
  int draggedId,
  int k,
) {
  final int index = rows.indexWhere((TaskItem r) => r.id == draggedId);
  if (index < 0) return rows;
  final TaskItem dragged = rows[index];
  final List<TaskItem> others = List<TaskItem>.of(rows)..removeAt(index);
  final List<TaskItem> pending =
      others.where((TaskItem r) => !r.done).toList();
  final List<TaskItem> done = others.where((TaskItem r) => r.done).toList();
  final List<TaskItem> block = dragged.done ? done : pending;
  final int clamped = k.clamp(0, block.length);
  block.insert(clamped, dragged);
  return <TaskItem>[...pending, ...done];
}

/// Compares two display lists structurally (freezed `==`); used to skip
/// no-change state writes so silent polls don't rebuild the UI.
bool sameItems(List<TaskItem> a, List<TaskItem> b) {
  return listEquals(a, b);
}
