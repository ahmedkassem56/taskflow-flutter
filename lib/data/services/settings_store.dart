import 'package:shared_preferences/shared_preferences.dart';

/// Key-value settings persisted via `shared_preferences` (web ⇒ localStorage,
/// Android ⇒ SharedPreferences), keys namespaced `taskflow.*` (DESIGN.md §9).
///
/// Every call is wrapped so plugin failures (private mode, tests without a
/// mocked platform channel) fall back to the in-memory map — the app never
/// crashes because persistence is unavailable (DESIGN.md §9).
class SettingsStore {
  SettingsStore._();

  static SharedPreferences? _prefs;
  static bool _loaded = false;

  /// In-memory fallback / mirror.
  static final Map<String, Object> _memory = <String, Object>{};

  static Future<SharedPreferences?> _instance() async {
    if (_loaded) return _prefs;
    _loaded = true;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
    return _prefs;
  }

  /// Reads [key]; null when absent or persistence is unavailable.
  static Future<String?> read(String key) async {
    final SharedPreferences? prefs = await _instance();
    if (prefs != null) {
      try {
        final String? stored = prefs.getString(key);
        if (stored != null) return stored;
      } catch (_) {
        // Fall through to the in-memory mirror.
      }
    }
    return _memory[key] as String?;
  }

  /// Writes [key] (fire-and-forget; the caller never awaits failure paths).
  static Future<void> write(String key, String value) async {
    _memory[key] = value;
    final SharedPreferences? prefs = await _instance();
    if (prefs == null) return;
    try {
      await prefs.setString(key, value);
    } catch (_) {
      // In-memory mirror already holds the value.
    }
  }

  /// Clears [key] (in-memory and persisted).
  static Future<void> remove(String key) async {
    _memory.remove(key);
    final SharedPreferences? prefs = await _instance();
    if (prefs == null) return;
    try {
      await prefs.remove(key);
    } catch (_) {
      // Ignore — mirror already cleared.
    }
  }

  /// Test hook: replaces the cached prefs handle so the next [read]/[write]
  /// re-resolves (shared_preferences mock values change between tests).
  static void resetForTest() {
    _prefs = null;
    _loaded = false;
    _memory.clear();
  }
}
