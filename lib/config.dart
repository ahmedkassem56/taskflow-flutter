/// Compile-time app configuration (DESIGN.md §9).
///
/// API base URL is overridable at build time:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

/// Polling interval for live-sync refreshes (DESIGN.md §5.2).
const Duration pollInterval = Duration(seconds: 5);

/// Timeout applied to every HTTP request (DESIGN.md §4).
const Duration requestTimeout = Duration(seconds: 10);

/// Debounce for the search box before a refetch fires (DESIGN.md §5.1).
const Duration queryDebounce = Duration(milliseconds: 300);
