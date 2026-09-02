// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'view_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// View selection + mode controller (DESIGN.md §5).
///
/// * Holds the app-mode selection (All | list id) and the app/share mode.
/// * Persists the selection under `taskflow.view` (`'all'` or the list id)
///   and restores it at boot — but only when that list still exists, else
///   All (validation runs against every `listsController` refresh; if the
///   current list vanishes the view drops back to All).
/// * Hosts the UI bookkeeping flags that suppress polling while a modal is
///   open, a drag is active, or the app is backgrounded (DESIGN.md §5.2) —
///   both item-polling controllers read them here so there is a single
///   source of truth.

@ProviderFor(ViewController)
final viewControllerProvider = ViewControllerProvider._();

/// View selection + mode controller (DESIGN.md §5).
///
/// * Holds the app-mode selection (All | list id) and the app/share mode.
/// * Persists the selection under `taskflow.view` (`'all'` or the list id)
///   and restores it at boot — but only when that list still exists, else
///   All (validation runs against every `listsController` refresh; if the
///   current list vanishes the view drops back to All).
/// * Hosts the UI bookkeeping flags that suppress polling while a modal is
///   open, a drag is active, or the app is backgrounded (DESIGN.md §5.2) —
///   both item-polling controllers read them here so there is a single
///   source of truth.
final class ViewControllerProvider
    extends $NotifierProvider<ViewController, ViewState> {
  /// View selection + mode controller (DESIGN.md §5).
  ///
  /// * Holds the app-mode selection (All | list id) and the app/share mode.
  /// * Persists the selection under `taskflow.view` (`'all'` or the list id)
  ///   and restores it at boot — but only when that list still exists, else
  ///   All (validation runs against every `listsController` refresh; if the
  ///   current list vanishes the view drops back to All).
  /// * Hosts the UI bookkeeping flags that suppress polling while a modal is
  ///   open, a drag is active, or the app is backgrounded (DESIGN.md §5.2) —
  ///   both item-polling controllers read them here so there is a single
  ///   source of truth.
  ViewControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewControllerHash();

  @$internal
  @override
  ViewController create() => ViewController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ViewState>(value),
    );
  }
}

String _$viewControllerHash() => r'ca4ee7b49111ef86325dbfe0b54aca457a4e637f';

/// View selection + mode controller (DESIGN.md §5).
///
/// * Holds the app-mode selection (All | list id) and the app/share mode.
/// * Persists the selection under `taskflow.view` (`'all'` or the list id)
///   and restores it at boot — but only when that list still exists, else
///   All (validation runs against every `listsController` refresh; if the
///   current list vanishes the view drops back to All).
/// * Hosts the UI bookkeeping flags that suppress polling while a modal is
///   open, a drag is active, or the app is backgrounded (DESIGN.md §5.2) —
///   both item-polling controllers read them here so there is a single
///   source of truth.

abstract class _$ViewController extends $Notifier<ViewState> {
  ViewState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ViewState, ViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ViewState, ViewState>,
              ViewState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
