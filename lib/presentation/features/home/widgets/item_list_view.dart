/// Shared scrollable task list used by the app view and the share view.
///
/// Renders [ItemRow]s separated by hairline dividers (web-parity rhythm). When
/// [reorderable] is true each row shows a trailing drag handle (immediate
/// drag) and the whole row also supports hold-to-drag
/// ([ReorderableDelayedDragStartListener]) — short taps still open the edit
/// sheet. Otherwise it is a plain list (read-only shares, All view) with no
/// handles.
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

  /// Enables reorder (drag handle + hold-to-drag). Requires [onReorder].
  final bool reorderable;
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Drag lifecycle hook (poll suppression), DESIGN.md §5.2.
  final ValueChanged<bool>? onRearrangeChanged;

  /// False while an optimistic toggle is in flight (DESIGN.md §5.3).
  final bool checkboxEnabled;

  Widget _hairline(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: 52,
        endIndent: 0,
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withValues(alpha: 0.45),
      );

  /// One keyed row: content + a hairline beneath it (except the last row).
  Widget _buildRow(BuildContext context, int index) {
    final TaskItem item = items[index];
    final bool isLast = index == items.length - 1;
    final bool interactive = onTapItem != null;
    final Widget row = ItemRow(
      key: ValueKey<int>(item.id),
      item: item,
      onToggle: onToggle,
      onTap: onTapItem == null ? null : () => onTapItem!(item),
      listName: listNameOf == null ? null : listNameOf!(item.listId),
      interactive: interactive,
      checkboxEnabled: checkboxEnabled,
      trailing: !reorderable || onReorder == null
          ? null
          : ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Icon(
                  Icons.drag_indicator,
                  key: Key('row-drag-handle-${item.id}'),
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.55),
                ),
              ),
            ),
    );

    final Widget content = isLast
        ? row
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[row, _hairline(context)],
          );

    if (!reorderable || onReorder == null) return content;
    // Hold-to-drag anywhere on the row (long press); short taps still edit.
    return ReorderableDelayedDragStartListener(
      key: ValueKey<int>(item.id),
      index: index,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!reorderable || onReorder == null) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) => _buildRow(context, index),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
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
      itemBuilder: (BuildContext context, int index) => _buildRow(context, index),
    );
  }
}
