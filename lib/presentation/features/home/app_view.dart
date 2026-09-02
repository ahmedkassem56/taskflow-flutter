/// App view: All tasks / single list with header, filter bar and the
/// reorderable item list (DESIGN.md §7).
///
/// All network mutations are delegated to the providers by name (DESIGN.md
/// §5); sites marked `ADAPT` were written against the documented contract
/// before the provider files landed and are reconciled at build time.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/task_item.dart';
import '../../../data/models/task_list.dart';
import '../../common/empty_states.dart';
import '../../common/format.dart';
import '../items/item_edit_sheet.dart';
import '../../providers/items.dart';
import '../../providers/lists.dart';
import '../../providers/mutation_bus.dart';
import '../../providers/view_controller.dart';
import 'widgets/filter_bar.dart';
import 'widgets/item_list_view.dart';
import 'widgets/list_actions.dart';
import 'widgets/list_sidebar.dart';

/// Opens the "new task" sheet in app mode.
///
/// In the All view a list picker is shown (default: first list); in a list
/// view the task is created in that list. Exposed for the shell FAB.
Future<void> openCreateItemSheet(BuildContext context, WidgetRef ref) async {
  final ViewState viewState = ref.read(viewControllerProvider);
  final List<TaskList> lists =
      ref.read(listsControllerProvider).value ?? const <TaskList>[];
  if (lists.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create a list first')),
    );
    return;
  }
  final bool isAll = isAllTasksView(viewState);
  final int initialListId =
      isAll ? lists.first.id : (currentListIdOf(viewState) ?? lists.first.id);

  // ADAPT(ViewController): dialog-open bookkeeping suppresses polling while
  // a modal is up (DESIGN.md §5.2).
  ref.read(viewControllerProvider.notifier).setDialogOpen(true);
  try {
    await showItemEditSheet(
      context,
      item: null,
      lists: lists,
      initialListId: initialListId,
      showListPicker: isAll,
      onSave: (ItemDraft draft) => _saveNewItem(ref, draft),
    );
  } finally {
    ref.read(viewControllerProvider.notifier).setDialogOpen(false);
  }
}

/// ADAPT(ItemsController): create item through the app-mode path.
Future<String?> _saveNewItem(WidgetRef ref, ItemDraft draft) async {
  try {
    await ref.read(itemsControllerProvider.notifier).createItem(
          listId: draft.listId,
          title: draft.title,
          notes: draft.notes.isEmpty ? null : draft.notes,
          priority: draft.priority,
          dueDate: draft.dueDate,
          quantity: draft.quantity,
          recurrence: draft.recurrence,
          recurrenceInterval: draft.recurrenceInterval,
        );
    return null;
  } catch (error) {
    return friendlyErrorMessage(error);
  }
}

/// Opens the "edit task" sheet for an existing item (app mode).
Future<void> openEditItemSheet(
  BuildContext context,
  WidgetRef ref,
  TaskItem item,
) async {
  final List<TaskList> lists =
      ref.read(listsControllerProvider).value ?? const <TaskList>[];
  // ADAPT(ViewController): dialog-open bookkeeping (DESIGN.md §5.2).
  ref.read(viewControllerProvider.notifier).setDialogOpen(true);
  try {
    await showItemEditSheet(
      context,
      item: item,
      lists: lists,
      initialListId: item.listId,
      showListPicker: false,
      onSave: (ItemDraft draft) => _saveEditedItem(ref, item, draft),
      onDelete: () => _deleteItem(ref, item),
    );
  } finally {
    ref.read(viewControllerProvider.notifier).setDialogOpen(false);
  }
}

/// ADAPT(ItemsController): update an existing item (partial patch).
Future<String?> _saveEditedItem(
  WidgetRef ref,
  TaskItem item,
  ItemDraft draft,
) async {
  try {
    await ref.read(itemsControllerProvider.notifier).updateItem(
          item.id,
          title: draft.title,
          notes: draft.notes.isEmpty ? null : draft.notes,
          priority: draft.priority,
          dueDate: draft.dueDate,
          quantity: draft.quantity,
          recurrence: draft.recurrence,
          recurrenceInterval: draft.recurrenceInterval,
        );
    return null;
  } catch (error) {
    return friendlyErrorMessage(error);
  }
}

/// ADAPT(ItemsController): delete an item.
Future<void> _deleteItem(WidgetRef ref, TaskItem item) async {
  try {
    await ref.read(itemsControllerProvider.notifier).deleteItem(item.id);
  } catch (error) {
    final String message = friendlyErrorMessage(error);
    // Deletion happens from the sheet; surface the error via the app root.
    // ignore: avoid_print
    debugPrint('deleteItem failed: $message');
  }
}

class AppView extends ConsumerStatefulWidget {
  const AppView({super.key});

  @override
  ConsumerState<AppView> createState() => _AppViewState();
}

class _AppViewState extends ConsumerState<AppView> {
  final TextEditingController _searchController = TextEditingController();
  StatusFilter _status = StatusFilter.all;
  bool _searchActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _searchActive = value.isNotEmpty;
    });
    // ADAPT(ItemsController): debounce is handled inside the controller.
    ref.read(itemsControllerProvider.notifier).setQuery(value);
  }

  void _onStatusChanged(StatusFilter status) {
    setState(() {
      _status = status;
    });
    // ADAPT(ItemsController): status refetch.
    ref.read(itemsControllerProvider.notifier).setStatus(status);
  }

  void _showError(Object error) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(friendlyErrorMessage(error))),
    );
  }

  Widget _buildBody(AsyncValue<List<TaskItem>> itemsAsync) {
    if (itemsAsync.isLoading && !itemsAsync.hasValue) {
      return const SkeletonList();
    }
    if (itemsAsync.hasError && !itemsAsync.hasValue) {
      return ErrorState(
        message: friendlyErrorMessage(
          itemsAsync.error!,
          fallback: 'Cannot reach the server. Check your connection.',
        ),
        onRetry: () => ref.invalidate(itemsControllerProvider),
      );
    }
    final List<TaskItem> items = itemsAsync.value ?? const <TaskItem>[];
    if (items.isEmpty) {
      return _buildEmptyState();
    }
    return _buildItemList(items);
  }

  Widget _buildEmptyState() {
    if (_searchActive) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No matching tasks',
        subtitle: 'Try a different search.',
      );
    }
    switch (_status) {
      case StatusFilter.pending:
        return const EmptyState(
          icon: Icons.check_circle_outline,
          title: 'No pending tasks',
          subtitle: 'Everything is done here.',
        );
      case StatusFilter.done:
        return const EmptyState(
          icon: Icons.radio_button_unchecked,
          title: 'No completed tasks',
          subtitle: 'Finish something to see it here.',
        );
      case StatusFilter.all:
        break;
    }
    return const EmptyState(
      icon: Icons.task_alt,
      title: 'No tasks yet',
      subtitle: 'Tap + to add your first task.',
    );
  }

  Widget _buildItemList(List<TaskItem> items) {
    final ViewState viewState = ref.watch(viewControllerProvider);
    final bool isList = !isAllTasksView(viewState);
    // DESIGN.md §8: reorder only in a single list view with no active query.
    final bool reorderEnabled = isList && !_searchActive;

    final List<TaskList> lists =
        ref.watch(listsControllerProvider).value ??
            const <TaskList>[];
    String? listNameOf(int listId) {
      for (final TaskList list in lists) {
        if (list.id == listId) return list.name;
      }
      return null;
    }

    // ADAPT(MutationBus): while any mutation is in flight the optimistic
    // toggle rows are disabled (DESIGN.md §5.3).
    final bool mutating = ref.watch(mutationBusProvider) > 0;

    return ItemListView(
      items: items,
      onToggle: (TaskItem item) => _toggle(item),
      onTapItem: (TaskItem item) => openEditItemSheet(context, ref, item),
      listNameOf: isAllTasksView(viewState) ? listNameOf : null,
      reorderable: reorderEnabled,
      onMoveUp: reorderEnabled
          ? (TaskItem item) => _moveItem(item, 'up')
          : null,
      onMoveDown: reorderEnabled
          ? (TaskItem item) => _moveItem(item, 'down')
          : null,
      onReorder: reorderEnabled ? _reorder : null,
      // ADAPT(ViewController): rearrange flag suppresses polls during drags.
      onRearrangeChanged: (bool active) {
        ref.read(viewControllerProvider.notifier).setRearrangeActive(active);
      },
      checkboxEnabled: !mutating,
    );
  }

  Future<void> _toggle(TaskItem item) async {
    try {
      // ADAPT(ItemsController): optimistic toggle with spawned handling.
      await ref.read(itemsControllerProvider.notifier).toggleDone(item);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _moveItem(TaskItem item, String direction) async {
    try {
      // ADAPT(ItemsController): PATCH {'move': 'up'|'down'}.
      await ref.read(itemsControllerProvider.notifier).moveItem(item, direction);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    try {
      // ADAPT(ItemsController): PATCH {'move_to': k} with optimistic rebuild.
      await ref.read(itemsControllerProvider.notifier).reorder(oldIndex, newIndex);
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AsyncValue<List<TaskItem>> itemsAsync =
        ref.watch(itemsControllerProvider);
    final AsyncValue<List<TaskList>> listsAsync =
        ref.watch(listsControllerProvider);
    final ViewState viewState = ref.watch(viewControllerProvider);
    final List<TaskList> lists = listsAsync.value ?? const <TaskList>[];

    final bool isAll = isAllTasksView(viewState);
    final int? listId = currentListIdOf(viewState);
    TaskList? currentList;
    int totalCount = 0;
    int pendingCount = 0;
    if (isAll) {
      for (final TaskList list in lists) {
        totalCount += list.itemCount;
        pendingCount += list.pendingCount;
      }
    } else {
      for (final TaskList list in lists) {
        if (list.id == listId) {
          currentList = list;
          totalCount = list.itemCount;
          pendingCount = list.pendingCount;
          break;
        }
      }
    }
    final String title =
        isAll ? 'All tasks' : (currentList?.name ?? 'Tasks');
    final String subtitle = progressLabel(totalCount, totalCount - pendingCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isAll && currentList != null)
                PopupMenuButton<String>(
                  tooltip: 'List actions',
                  onSelected: (String action) {
                    switch (action) {
                      case 'rename':
                        renameListFlow(context, ref, currentList!);
                      case 'share':
                        shareListFlow(context, ref, currentList!);
                      case 'delete':
                        deleteListFlow(context, ref, currentList!);
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
        FilterBar(
          status: _status,
          onStatusChanged: _onStatusChanged,
          searchController: _searchController,
          onQueryChanged: _onQueryChanged,
        ),
        Expanded(child: _buildBody(itemsAsync)),
      ],
    );
  }
}
