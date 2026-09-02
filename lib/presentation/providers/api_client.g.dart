// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [ApiClient] — base URL from compile-time config (DESIGN.md §9).
///
/// Generated as `@riverpod class ApiClientProvider`, so the provider
/// identifier is `apiClientProviderProvider` (class name + `Provider`
/// suffix). Tests override it with a MockClient-backed instance:
/// `apiClientProviderProvider.overrideWithValue(ApiClient(...))`.

@ProviderFor(ApiClientProvider)
final apiClientProviderProvider = ApiClientProviderProvider._();

/// The app's [ApiClient] — base URL from compile-time config (DESIGN.md §9).
///
/// Generated as `@riverpod class ApiClientProvider`, so the provider
/// identifier is `apiClientProviderProvider` (class name + `Provider`
/// suffix). Tests override it with a MockClient-backed instance:
/// `apiClientProviderProvider.overrideWithValue(ApiClient(...))`.
final class ApiClientProviderProvider
    extends $NotifierProvider<ApiClientProvider, ApiClient> {
  /// The app's [ApiClient] — base URL from compile-time config (DESIGN.md §9).
  ///
  /// Generated as `@riverpod class ApiClientProvider`, so the provider
  /// identifier is `apiClientProviderProvider` (class name + `Provider`
  /// suffix). Tests override it with a MockClient-backed instance:
  /// `apiClientProviderProvider.overrideWithValue(ApiClient(...))`.
  ApiClientProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProviderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientProviderHash();

  @$internal
  @override
  ApiClientProvider create() => ApiClientProvider();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiClient>(value),
    );
  }
}

String _$apiClientProviderHash() => r'f7f4f2912172cf34ff28d40d50badcdbb85275fa';

/// The app's [ApiClient] — base URL from compile-time config (DESIGN.md §9).
///
/// Generated as `@riverpod class ApiClientProvider`, so the provider
/// identifier is `apiClientProviderProvider` (class name + `Provider`
/// suffix). Tests override it with a MockClient-backed instance:
/// `apiClientProviderProvider.overrideWithValue(ApiClient(...))`.

abstract class _$ApiClientProvider extends $Notifier<ApiClient> {
  ApiClient build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ApiClient, ApiClient>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ApiClient, ApiClient>,
              ApiClient,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
