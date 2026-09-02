/// Shared scrollable task list used by the app view and the share view.
///
/// Renders [ItemRow]s in server order. When [reorderable] is true the list is
/// a [ReorderableListView] with every row wrapped in a
/// [ReorderableDelayedDragStartListener] (hold ~500 ms to drag — short taps
/// still open the edit sheet); otherwise it is a plain list (read-only shares,
/// All view). Arrows are exposed only while [reorderable].
library;

import 'package:flutter/material.dart';

import '../../../../data/models/task_item.dart';
import 'item_row.dart';

class ItemListView extends StatelessWidget {
  const ItemListView({
    super.key,
    required this.items,
    required this.onToggle,
    this.onTapItem,
    this.listNameOf,
    this.reorderable = false,
    this.onMoveUp,
    this.onMoveDown,
    this.onReorder,
    this.onRearrangeChanged,
    this.checkboxEnabled = true,
  });

  final List<TaskItem> items;
  final ValueChanged<TaskItem> onToggle;

  /// Row tap handler; null renders rows without tap handling (read-only).
  final ValueChanged<TaskItem>? onTapItem;

  /// Resolves a list id to its display name for the "All tasks" list-name
  /// chip; null hides the chip entirely.
  final String? Function(int listId)? listNameOf;

  /// Enables hold-to-drag reorder. Requires [onReorder].
  final bool reorderable;
  final ValueChanged<TaskItem>? onMoveUp;
  final ValueChanged<TaskItem>? onMoveDown;
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Drag lifecycle hook (poll suppression), DESIGN.md §5.2.
  final ValueChanged<bool>? onRearrangeChanged;

  /// False while an optimistic toggle is in flight (DESIGN.md §5.3).
  final bool checkboxEnabled;

  Widget _buildRow(int index) {
    final TaskItem item = items[index];
    final bool interactive = onTapItem != null || onMoveUp != null;
    final Widget row = ItemRow(
      key: ValueKey<int>(item.id),
      item: item,
      onToggle: onToggle,
      onTap: onTapItem == null ? null : () => onTapItem!(item),
      listName: listNameOf == null ? null : listNameOf!(item.listId),
      interactive: interactive,
      checkboxEnabled: checkboxEnabled,
      onMoveUp: onMoveUp == null ? null : () => onMoveUp!(item),
      onMoveDown: onMoveDown == null ? null : () => onMoveDown!(item),
    );
    if (!reorderable || onReorder == null) return row;
    return ReorderableDelayedDragStartListener(
      key: ValueKey<int>(item.id),
      index: index,
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!reorderable || onReorder == null) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) => _buildRow(index),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      // DESIGN.md §8 ordinal mapping uses the classic onReorder index
      // convention (newIndex > oldIndex ⇒ newIndex--), so stay on the
      // legacy callback rather than onReorderItem's pre-adjusted index.
      // ignore: deprecated_member_use
      onReorder: onReorder!,
      onReorderStart: onRearrangeChanged == null
          ? null
          : (int index) => onRearrangeChanged!(true),
      onReorderEnd: onRearrangeChanged == null
          ? null
          : (int index) => onRearrangeChanged!(false),
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? animatedChild) {
            return Material(
              color: Colors.transparent,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: animatedChild,
            );
          },
          child: child,
        );
      },
      itemBuilder: (BuildContext context, int index) => _buildRow(index),
    );
  }
}
