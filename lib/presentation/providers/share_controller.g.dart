// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Share-mode controller (DESIGN.md §5): loads `GET /api/shared/{token}`
/// (all items — the shared endpoint has no status/q params; the UI filters
/// client-side over `state.items`, which stays the full canonical list).
///
/// * `load(token)` drives the initial fetch and every retry; while no token
///   is loaded the provider stays in AsyncLoading.
/// * The provider is auto-disposed when the share page unmounts (nothing
///   watches it), which also stops its 5s poll — polls only ever run while
///   the share page is on screen (DESIGN.md §5.2).
/// * Toggle-done is optimistic (DESIGN.md §5.3) — flip + canonical re-sort,
///   PATCH, envelope merge (`item` replacement, `spawned` insertion at
///   pending-top), revert on error — create/edit/delete/reorder are awaited
///   then silently refreshed. Writes require `permission == edit`
///   ([canEdit]); read-only tokens get 403s from the server, and this
///   controller refuses local optimistic ops it can't perform.

@ProviderFor(ShareController)
final shareControllerProvider = ShareControllerProvider._();

/// Share-mode controller (DESIGN.md §5): loads `GET /api/shared/{token}`
/// (all items — the shared endpoint has no status/q params; the UI filters
/// client-side over `state.items`, which stays the full canonical list).
///
/// * `load(token)` drives the initial fetch and every retry; while no token
///   is loaded the provider stays in AsyncLoading.
/// * The provider is auto-disposed when the share page unmounts (nothing
///   watches it), which also stops its 5s poll — polls only ever run while
///   the share page is on screen (DESIGN.md §5.2).
/// * Toggle-done is optimistic (DESIGN.md §5.3) — flip + canonical re-sort,
///   PATCH, envelope merge (`item` replacement, `spawned` insertion at
///   pending-top), revert on error — create/edit/delete/reorder are awaited
///   then silently refreshed. Writes require `permission == edit`
///   ([canEdit]); read-only tokens get 403s from the server, and this
///   controller refuses local optimistic ops it can't perform.
final class ShareControllerProvider
    extends $AsyncNotifierProvider<ShareController, SharedList> {
  /// Share-mode controller (DESIGN.md §5): loads `GET /api/shared/{token}`
  /// (all items — the shared endpoint has no status/q params; the UI filters
  /// client-side over `state.items`, which stays the full canonical list).
  ///
  /// * `load(token)` drives the initial fetch and every retry; while no token
  ///   is loaded the provider stays in AsyncLoading.
  /// * The provider is auto-disposed when the share page unmounts (nothing
  ///   watches it), which also stops its 5s poll — polls only ever run while
  ///   the share page is on screen (DESIGN.md §5.2).
  /// * Toggle-done is optimistic (DESIGN.md §5.3) — flip + canonical re-sort,
  ///   PATCH, envelope merge (`item` replacement, `spawned` insertion at
  ///   pending-top), revert on error — create/edit/delete/reorder are awaited
  ///   then silently refreshed. Writes require `permission == edit`
  ///   ([canEdit]); read-only tokens get 403s from the server, and this
  ///   controller refuses local optimistic ops it can't perform.
  ShareControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareControllerHash();

  @$internal
  @override
  ShareController create() => ShareController();
}

String _$shareControllerHash() => r'3c4bbd3e2b61ae76368fe832f5000d1d99b754b7';

/// Share-mode controller (DESIGN.md §5): loads `GET /api/shared/{token}`
/// (all items — the shared endpoint has no status/q params; the UI filters
/// client-side over `state.items`, which stays the full canonical list).
///
/// * `load(token)` drives the initial fetch and every retry; while no token
///   is loaded the provider stays in AsyncLoading.
/// * The provider is auto-disposed when the share page unmounts (nothing
///   watches it), which also stops its 5s poll — polls only ever run while
///   the share page is on screen (DESIGN.md §5.2).
/// * Toggle-done is optimistic (DESIGN.md §5.3) — flip + canonical re-sort,
///   PATCH, envelope merge (`item` replacement, `spawned` insertion at
///   pending-top), revert on error — create/edit/delete/reorder are awaited
///   then silently refreshed. Writes require `permission == edit`
///   ([canEdit]); read-only tokens get 403s from the server, and this
///   controller refuses local optimistic ops it can't perform.

abstract class _$ShareController extends $AsyncNotifier<SharedList> {
  FutureOr<SharedList> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SharedList>, SharedList>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SharedList>, SharedList>,
              AsyncValue<SharedList>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
