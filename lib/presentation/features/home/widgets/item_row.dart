/// One task row: checkbox, title/notes, meta chips and an optional trailing
/// drag handle.
///
/// Rows are intentionally dumb — the parent list owns reorder wrapping
/// (`ReorderableDelayedDragStartListener` around the row for long-press drag,
/// plus an immediate `ReorderableDragStartListener` around [trailing] for the
/// visible drag handle) and passes callbacks in. When [trailing] is null the
/// handle area is hidden entirely. [interactive] gates the checkbox; when
/// `false` (read-only share) taps do nothing at all (JS parity).
library;

import 'package:flutter/material.dart';

import '../../../../data/models/task_item.dart';
import '../../../common/format.dart';

/// A small pill chip used for item metadata.
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.color,
    this.icon,
  });

  final String label;

  /// Label + dot tint; `null` falls back to the muted text color.
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Colored labels are tinted toward onSurface so chip text clears WCAG AA
    // (4.5:1) on surfaceContainerHighest in both themes; the dot stays vivid.
    final Color effective = color ?? scheme.onSurfaceVariant;
    final Color labelColor = color == null
        ? scheme.onSurfaceVariant
        : Color.lerp(color, scheme.onSurface, 0.38)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 11, color: effective),
            const SizedBox(width: 4),
          ] else ...<Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: effective,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// One task row.
///
/// [listName] is shown as a chip only when the row is rendered in the "All
/// tasks" cross-list view. [interactive] gates the checkbox; when `false`
/// (read-only share) taps do nothing at all (JS parity).
class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.item,
    required this.onToggle,
    this.onTap,
    this.listName,
    this.interactive = true,
    this.trailing,
    this.checkboxEnabled = true,
  });

  final TaskItem item;
  final ValueChanged<TaskItem> onToggle;
  final VoidCallback? onTap;
  final String? listName;
  final bool interactive;

  /// Optional right-edge widget (e.g. the reorder drag handle, built by the
  /// parent with its own drag listener). Null hides the column entirely.
  final Widget? trailing;

  /// False while an optimistic toggle for this row is in flight.
  final bool checkboxEnabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool done = item.done;

    final List<Widget> chips = <Widget>[];
    if (listName != null && listName!.isNotEmpty) {
      chips.add(_MetaChip(label: listName!));
    }
    final String? prioLabel = priorityLabel(item.priority);
    if (prioLabel != null) {
      chips.add(
        _MetaChip(
          label: prioLabel,
          color: priorityChipColor(item.priority),
        ),
      );
    }
    final String? due = item.dueDate;
    if (due != null && due.isNotEmpty) {
      chips.add(
        _MetaChip(
          label: dueLabel(due),
          color: isOverdue(due)
              ? scheme.error
              : isDueToday(due)
                  ? scheme.primary
                  : null,
        ),
      );
    }
    if (item.quantity != 1) {
      chips.add(
        _MetaChip(
          label: 'x${formatQuantity(item.quantity)}',
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    final String rec = recurrenceLabel(item.recurrence, item.recurrenceInterval);
    if (rec.isNotEmpty) {
      chips.add(_MetaChip(label: rec, icon: Icons.repeat));
    }

    final Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Checkbox(
            value: done,
            onChanged: interactive && checkboxEnabled
                ? (bool? _) => onToggle(item)
                : null,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: textTheme.bodyLarge?.copyWith(
                    color: done ? scheme.onSurfaceVariant : scheme.onSurface,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    item.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (chips.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: chips,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: trailing,
          ),
      ],
    );

    if (!interactive) {
      // Read-only share: no tap handling at all.
      return content;
    }
    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}
