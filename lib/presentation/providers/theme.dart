import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/settings_store.dart';

part 'theme.g.dart';

/// App theme mode (light | dark | system), persisted under `taskflow.theme`
/// (DESIGN.md §9). The toggle cycles light → dark → system.
///
/// Persistence goes through [SettingsStore] (SharedPreferences with an
/// in-memory fallback), so the controller never crashes in private mode.
@Riverpod(keepAlive: true)
class ThemeController extends _$ThemeController {
  static const String prefsKey = 'taskflow.theme';

  bool _restoreAttempted = false;

  @override
  ThemeMode build() {
    _attemptRestore();
    return ThemeMode.system;
  }

  /// Cycles light → dark → system (DESIGN.md §9).
  void cycleTheme() {
    final ThemeMode current = state;
    final ThemeMode next = switch (current) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    setTheme(next);
  }

  /// Sets (and persists) the theme mode.
  void setTheme(ThemeMode mode) {
    state = mode;
    SettingsStore.write(prefsKey, mode.name);
  }

  Future<void> _attemptRestore() async {
    if (_restoreAttempted) return;
    _restoreAttempted = true;
    try {
      final String? raw = await SettingsStore.read(prefsKey);
      if (raw == null) return;
      for (final ThemeMode mode in ThemeMode.values) {
        if (mode.name == raw) {
          if (ref.mounted && state != mode) state = mode;
          return;
        }
      }
    } catch (_) {
      // Never crash on persistence failures.
    }
  }
}
