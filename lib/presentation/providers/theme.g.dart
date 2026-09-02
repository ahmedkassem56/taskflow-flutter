// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App theme mode (light | dark | system), persisted under `taskflow.theme`
/// (DESIGN.md §9). The toggle cycles light → dark → system.
///
/// Persistence goes through [SettingsStore] (SharedPreferences with an
/// in-memory fallback), so the controller never crashes in private mode.

@ProviderFor(ThemeController)
final themeControllerProvider = ThemeControllerProvider._();

/// App theme mode (light | dark | system), persisted under `taskflow.theme`
/// (DESIGN.md §9). The toggle cycles light → dark → system.
///
/// Persistence goes through [SettingsStore] (SharedPreferences with an
/// in-memory fallback), so the controller never crashes in private mode.
final class ThemeControllerProvider
    extends $NotifierProvider<ThemeController, ThemeMode> {
  /// App theme mode (light | dark | system), persisted under `taskflow.theme`
  /// (DESIGN.md §9). The toggle cycles light → dark → system.
  ///
  /// Persistence goes through [SettingsStore] (SharedPreferences with an
  /// in-memory fallback), so the controller never crashes in private mode.
  ThemeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeControllerHash();

  @$internal
  @override
  ThemeController create() => ThemeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeControllerHash() => r'c4c9daaba659cc2ee0f6a78151399740ecd90bc1';

/// App theme mode (light | dark | system), persisted under `taskflow.theme`
/// (DESIGN.md §9). The toggle cycles light → dark → system.
///
/// Persistence goes through [SettingsStore] (SharedPreferences with an
/// in-memory fallback), so the controller never crashes in private mode.

abstract class _$ThemeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
