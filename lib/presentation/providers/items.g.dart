// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-mode items (DESIGN.md §5): the display list for the current view
/// (All | list), status filter and debounced query.
///
/// * Server-side filtering: every fetch is `GET /api/items` with `list_id`
///   (list view only), `status` (only when ≠ all) and `q` (when non-empty).
/// * View switches (watch on [viewControllerProvider]) rebuild this provider
///   and refetch the new context; status/query changes refetch silently.
/// * Polling (DESIGN.md §5.2): 5s tick, skipped while the page is hidden, a
///   modal is open, a drag is active, a fetch is in flight, or a mutation is
///   running. Auto-disposed when nothing listens (e.g. while the share route
///   shows), so polls never run off-screen.
/// * Staleness guard: every fetch captures `(listId, status, q, mutation
///   gen)`; a response completing after any of those changed is discarded —
///   the newer mutation/fetch wins until its own settle refresh.
/// * Mutations per DESIGN.md §5.3: toggle-done is the only optimistic op;
///   create/edit/delete are awaited then silently refreshed.

@ProviderFor(ItemsController)
final itemsControllerProvider = ItemsControllerProvider._();

/// App-mode items (DESIGN.md §5): the display list for the current view
/// (All | list), status filter and debounced query.
///
/// * Server-side filtering: every fetch is `GET /api/items` with `list_id`
///   (list view only), `status` (only when ≠ all) and `q` (when non-empty).
/// * View switches (watch on [viewControllerProvider]) rebuild this provider
///   and refetch the new context; status/query changes refetch silently.
/// * Polling (DESIGN.md §5.2): 5s tick, skipped while the page is hidden, a
///   modal is open, a drag is active, a fetch is in flight, or a mutation is
///   running. Auto-disposed when nothing listens (e.g. while the share route
///   shows), so polls never run off-screen.
/// * Staleness guard: every fetch captures `(listId, status, q, mutation
///   gen)`; a response completing after any of those changed is discarded —
///   the newer mutation/fetch wins until its own settle refresh.
/// * Mutations per DESIGN.md §5.3: toggle-done is the only optimistic op;
///   create/edit/delete are awaited then silently refreshed.
final class ItemsControllerProvider
    extends $AsyncNotifierProvider<ItemsController, List<TaskItem>> {
  /// App-mode items (DESIGN.md §5): the display list for the current view
  /// (All | list), status filter and debounced query.
  ///
  /// * Server-side filtering: every fetch is `GET /api/items` with `list_id`
  ///   (list view only), `status` (only when ≠ all) and `q` (when non-empty).
  /// * View switches (watch on [viewControllerProvider]) rebuild this provider
  ///   and refetch the new context; status/query changes refetch silently.
  /// * Polling (DESIGN.md §5.2): 5s tick, skipped while the page is hidden, a
  ///   modal is open, a drag is active, a fetch is in flight, or a mutation is
  ///   running. Auto-disposed when nothing listens (e.g. while the share route
  ///   shows), so polls never run off-screen.
  /// * Staleness guard: every fetch captures `(listId, status, q, mutation
  ///   gen)`; a response completing after any of those changed is discarded —
  ///   the newer mutation/fetch wins until its own settle refresh.
  /// * Mutations per DESIGN.md §5.3: toggle-done is the only optimistic op;
  ///   create/edit/delete are awaited then silently refreshed.
  ItemsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'itemsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$itemsControllerHash();

  @$internal
  @override
  ItemsController create() => ItemsController();
}

String _$itemsControllerHash() => r'6bebef546a03dd6a75708f0a1f4921365ce467a1';

/// App-mode items (DESIGN.md §5): the display list for the current view
/// (All | list), status filter and debounced query.
///
/// * Server-side filtering: every fetch is `GET /api/items` with `list_id`
///   (list view only), `status` (only when ≠ all) and `q` (when non-empty).
/// * View switches (watch on [viewControllerProvider]) rebuild this provider
///   and refetch the new context; status/query changes refetch silently.
/// * Polling (DESIGN.md §5.2): 5s tick, skipped while the page is hidden, a
///   modal is open, a drag is active, a fetch is in flight, or a mutation is
///   running. Auto-disposed when nothing listens (e.g. while the share route
///   shows), so polls never run off-screen.
/// * Staleness guard: every fetch captures `(listId, status, q, mutation
///   gen)`; a response completing after any of those changed is discarded —
///   the newer mutation/fetch wins until its own settle refresh.
/// * Mutations per DESIGN.md §5.3: toggle-done is the only optimistic op;
///   create/edit/delete are awaited then silently refreshed.

abstract class _$ItemsController extends $AsyncNotifier<List<TaskItem>> {
  FutureOr<List<TaskItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<TaskItem>>, List<TaskItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TaskItem>>, List<TaskItem>>,
              AsyncValue<List<TaskItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
