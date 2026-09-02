/// Sidebar navigation: All tasks + lists with badges, New list.
///
/// Rendered inside the wide NavigationRail-style column and inside the narrow
/// drawer (see home_shell.dart). List rows carry an overflow menu with
/// rename / share / delete actions, mirroring the JS client's hover actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/task_list.dart';
import '../../../providers/lists.dart';
import '../../../providers/view_controller.dart';
import 'list_actions.dart';

/// Extracts the currently selected list id from the view state.
///
/// ADAPT(ViewState): assumes `ViewState { ViewMode mode, TaskView view }`
/// with `TaskView` freezed union `all()` / `list(int id)` — DESIGN.md §5.
bool isAllTasksView(ViewState state) {
  final bool isAll = state.view.when(
    all: () => true,
    list: (int id) => false,
  );
  return isAll;
}

/// ADAPT(ViewState): current list id, or null when the All view is active.
int? currentListIdOf(ViewState state) {
  return state.view.when<int?>(
    all: () => null,
    list: (int id) => id,
  );
}

/// ADAPT(ViewState): true when the app is in share mode.
bool isShareMode(ViewState state) => state.mode == ViewMode.share;

class ListSidebar extends ConsumerWidget {
  const ListSidebar({super.key, this.onNavigate});

  /// Called after a view selection so drawers can close themselves.
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<List<TaskList>> listsAsync =
        ref.watch(listsControllerProvider);
    final ViewState viewState = ref.watch(viewControllerProvider);
    final List<TaskList> lists = listsAsync.value ?? const <TaskList>[];

    final int totalPending = lists.fold<int>(
      0,
      (int sum, TaskList l) => sum + l.pendingCount,
    );
    final bool allSelected = isAllTasksView(viewState);
    final int? selectedId = currentListIdOf(viewState);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: <Widget>[
        _NavRow(
          leading: Icons.inbox_outlined,
          label: 'All tasks',
          count: totalPending,
          selected: allSelected,
          onTap: () {
            ref.read(viewControllerProvider.notifier).selectAll();
            onNavigate?.call();
          },
        ),
        for (final TaskList list in lists)
          _ListNavRow(
            list: list,
            selected: list.id == selectedId,
            onTap: () {
              ref.read(viewControllerProvider.notifier).selectList(list.id);
              onNavigate?.call();
            },
            onRename: () => renameListFlow(context, ref, list),
            onShare: () => shareListFlow(context, ref, list),
            onDelete: () => deleteListFlow(context, ref, list),
          ),
        if (lists.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'No lists yet — create one to get started.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: OutlinedButton.icon(
            key: const Key('new-list-button'),
            onPressed: () => createListFlow(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New list'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.leading,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData leading;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: <Widget>[
                Icon(
                  leading,
                  size: 20,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListNavRow extends StatelessWidget {
  const _ListNavRow({
    required this.list,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onShare,
    required this.onDelete,
  });

  final TaskList list;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.list_alt_outlined,
                  size: 20,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    list.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (list.pendingCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${list.pendingCount}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  tooltip: 'List actions',
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  onSelected: (String action) {
                    switch (action) {
                      case 'rename':
                        onRename();
                      case 'share':
                        onShare();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (BuildContext menuContext) =>
                      const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined, size: 18),
                        title: Text('Rename'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'share',
                      child: ListTile(
                        leading: Icon(Icons.link, size: 18),
                        title: Text('Share'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, size: 18),
                        title: Text('Delete'),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
