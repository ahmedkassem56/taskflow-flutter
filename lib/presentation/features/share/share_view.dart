/// Shared-list page: identity header, client-side filters and item list.
///
/// Route target for `/share/:token` (go_router). Editing is allowed only for
/// `permission == edit` tokens; read-only shares render rows without
/// checkboxes/arrows/drag and show no create action (DESIGN.md §5.1, §8).
/// The shared endpoint has no server-side `status`/`q` params, so filtering
/// happens client-side here.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/shared_list.dart';
import '../../../data/models/task_item.dart';
import '../../../data/models/task_list.dart';
import '../../common/empty_states.dart';
import '../../common/format.dart';
import '../../providers/share_controller.dart';
import '../../providers/theme.dart';
import '../home/widgets/filter_bar.dart';
import '../home/widgets/item_list_view.dart';
import '../items/item_edit_sheet.dart';

/// Loads the shared list for [token] and renders the full share page.
class SharePage extends ConsumerStatefulWidget {
  const SharePage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<SharePage> createState() => _SharePageState();
}

class _SharePageState extends ConsumerState<SharePage> {
  @override
  void initState() {
    super.initState();
    // Load on the first frame so the router build is side-effect free.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      _load();
    });
  }

  void _load() {
    // ADAPT(ShareController): fetch the shared list by token.
    ref.read(shareControllerProvider.notifier).load(widget.token);
  }

  Future<void> _openCreate() async {
    final SharedList? share = ref.read(shareControllerProvider).value;
    if (share == null) return;
    await showItemEditSheet(
      context,
      item: null,
      lists: <TaskList>[share.list],
      initialListId: share.list.id,
      showListPicker: false,
      onSave: (ItemDraft draft) async {
        try {
          // ADAPT(ShareController): create via /api/shared/{token}/items.
          await ref.read(shareControllerProvider.notifier).createItem(
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<SharedList> shareAsync =
        ref.watch(shareControllerProvider);
    final SharedList? share = shareAsync.value;
    final bool canEdit = share?.canEdit ?? false;
    final ThemeMode themeMode = ref.watch(themeControllerProvider);

    void cycleTheme() {
      // ADAPT(ThemeController): cycles light -> dark -> system.
      ref.read(themeControllerProvider.notifier).cycleTheme();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Taskflow',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          share?.list.name ?? 'Shared list',
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          if (canEdit)
            IconButton(
              key: const Key('share-add-button'),
              tooltip: 'Add task',
              icon: const Icon(Icons.add),
              onPressed: _openCreate,
            ),
          IconButton(
            key: const Key('share-theme-toggle'),
            tooltip: 'Toggle theme',
            icon: Icon(
              switch (themeMode) {
                ThemeMode.light => Icons.dark_mode_outlined,
                ThemeMode.dark => Icons.light_mode_outlined,
                ThemeMode.system => Icons.brightness_auto_outlined,
              },
            ),
            onPressed: cycleTheme,
          ),
        ],
      ),
      body: ShareView(token: widget.token),
    );
  }
}

class ShareView extends ConsumerStatefulWidget {
  const ShareView({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ShareView> createState() => _ShareViewState();
}

class _ShareViewState extends ConsumerState<ShareView> {
  final TextEditingController _searchController = TextEditingController();
  StatusFilter _status = StatusFilter.all;
  bool _searchActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(TaskItem item, String query) {
    if (query.isEmpty) return true;
    final String needle = query.toLowerCase();
    if (item.title.toLowerCase().contains(needle)) return true;
    final String? notes = item.notes;
    return notes != null && notes.toLowerCase().contains(needle);
  }

  List<TaskItem> _filter(List<TaskItem> items) {
    final String query = _searchController.text.trim().toLowerCase();
    return <TaskItem>[
      for (final TaskItem item in items)
        if ((_status == StatusFilter.all ||
                (_status == StatusFilter.pending && !item.done) ||
                (_status == StatusFilter.done && item.done)) &&
            _matchesQuery(item, query))
          item,
    ];
  }

  void _showError(Object error) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(friendlyErrorMessage(error))),
    );
  }

  Widget _buildBody(AsyncValue<SharedList> shareAsync) {
    if (shareAsync.isLoading && !shareAsync.hasValue) {
      return const SkeletonList();
    }
    if (shareAsync.hasError && !shareAsync.hasValue) {
      return ErrorState(
        message: friendlyErrorMessage(
          shareAsync.error!,
          fallback: 'Share link not found or revoked.',
        ),
        onRetry: () {
          // ADAPT(ShareController): retry load.
          ref.read(shareControllerProvider.notifier).load(widget.token);
        },
      );
    }
    final SharedList? share = shareAsync.value;
    if (share == null) return const SizedBox.shrink();
    final List<TaskItem> filtered = _filter(share.items);
    if (filtered.isEmpty) {
      return _buildEmptyState(share.items.isEmpty);
    }
    return _buildItemList(share, filtered);
  }

  Widget _buildEmptyState(bool listEmpty) {
    if (_searchActive) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No matching tasks',
        subtitle: 'Try a different search.',
      );
    }
    if (!listEmpty) {
      switch (_status) {
        case StatusFilter.pending:
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No pending tasks',
          );
        case StatusFilter.done:
          return const EmptyState(
            icon: Icons.radio_button_unchecked,
            title: 'No completed tasks',
          );
        case StatusFilter.all:
          break;
      }
    }
    return const EmptyState(
      icon: Icons.task_alt,
      title: 'No tasks yet',
    );
  }

  Widget _buildItemList(SharedList share, List<TaskItem> items) {
    final bool canEdit = share.canEdit;
    // DESIGN.md §8: reorder only with an edit token and no active query.
    final bool reorderEnabled = canEdit && !_searchActive;

    return ItemListView(
      items: items,
      onToggle: canEdit ? _toggle : (TaskItem item) {},
      onTapItem: canEdit ? _openEdit : null,
      listNameOf: null,
      reorderable: reorderEnabled,
      onMoveUp: reorderEnabled ? (TaskItem item) => _moveItem(item, 'up') : null,
      onMoveDown: reorderEnabled
          ? (TaskItem item) => _moveItem(item, 'down')
          : null,
      onReorder: reorderEnabled ? _reorder : null,
    );
  }

  Future<void> _toggle(TaskItem item) async {
    try {
      // ADAPT(ShareController): toggle via /api/shared/{token}/items.
      await ref.read(shareControllerProvider.notifier).toggleDone(item);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _moveItem(TaskItem item, String direction) async {
    try {
      // ADAPT(ShareController): move via the shared endpoint.
      await ref
          .read(shareControllerProvider.notifier)
          .moveItem(item, direction);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    try {
      // ADAPT(ShareController): move_to via the shared endpoint.
      await ref
          .read(shareControllerProvider.notifier)
          .reorder(oldIndex, newIndex);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _openEdit(TaskItem item) async {
    final SharedList? share = ref.read(shareControllerProvider).value;
    if (share == null) return;
    await showItemEditSheet(
      context,
      item: item,
      lists: <TaskList>[share.list],
      initialListId: share.list.id,
      showListPicker: false,
      onSave: (ItemDraft draft) async {
        try {
          // ADAPT(ShareController): update via the shared endpoint.
          await ref.read(shareControllerProvider.notifier).updateItem(
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
      },
      onDelete: () async {
        // ADAPT(ShareController): delete via the shared endpoint.
        await ref.read(shareControllerProvider.notifier).deleteItem(item.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<SharedList> shareAsync =
        ref.watch(shareControllerProvider);
    final SharedList? share = shareAsync.value;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (share != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        share.list.name,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: share.canEdit
                            ? scheme.secondaryContainer
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        share.canEdit ? 'Can edit' : 'Read-only',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: share.canEdit
                              ? scheme.onSecondaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  progressLabel(
                    share.list.itemCount,
                    share.list.itemCount - share.list.pendingCount,
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                // "Open Taskflow": the JS PWA link for this shared list,
                // displayed verbatim (DESIGN.md §9). Without a launcher
                // dependency the Flutter client renders it copyable.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          '$apiBaseUrl/share/${widget.token}',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        FilterBar(
          status: _status,
          onStatusChanged: (StatusFilter status) {
            setState(() {
              _status = status;
            });
          },
          searchController: _searchController,
          onQueryChanged: (String value) {
            setState(() {
              _searchActive = value.isNotEmpty;
            });
          },
        ),
        Expanded(child: _buildBody(shareAsync)),
      ],
    );
  }
}
