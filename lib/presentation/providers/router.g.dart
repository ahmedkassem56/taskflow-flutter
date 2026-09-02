// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's go_router instance (DESIGN.md §6), built once from
/// [buildAppRouter]. Consumed by `MaterialApp.router` in `lib/app.dart`.

@ProviderFor(RouterProvider)
final routerProviderProvider = RouterProviderProvider._();

/// The app's go_router instance (DESIGN.md §6), built once from
/// [buildAppRouter]. Consumed by `MaterialApp.router` in `lib/app.dart`.
final class RouterProviderProvider
    extends $NotifierProvider<RouterProvider, GoRouter> {
  /// The app's go_router instance (DESIGN.md §6), built once from
  /// [buildAppRouter]. Consumed by `MaterialApp.router` in `lib/app.dart`.
  RouterProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProviderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerProviderHash();

  @$internal
  @override
  RouterProvider create() => RouterProvider();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerProviderHash() => r'07aeb7b54f0458ce33acaf7d7739b094a5f75828';

/// The app's go_router instance (DESIGN.md §6), built once from
/// [buildAppRouter]. Consumed by `MaterialApp.router` in `lib/app.dart`.

abstract class _$RouterProvider extends $Notifier<GoRouter> {
  GoRouter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoRouter, GoRouter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoRouter, GoRouter>,
              GoRouter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
