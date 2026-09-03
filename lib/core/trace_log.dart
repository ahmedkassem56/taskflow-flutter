/// Minimal in-app trace log for diagnosing the quick-add race on real devices.
///
/// Enabled at build time with `--dart-define=TRACE_ADD=true`. Collects the
/// last [TraceLog.maxEvents] events (timestamped) into a global ring that a
/// debug overlay renders. `print` also emits so `adb logcat` can capture it.
library;

/// Set to true when the app is built with `--dart-define=TRACE_ADD=true`.
const bool kTraceAdd = bool.fromEnvironment('TRACE_ADD');

final TraceLog traceLog = TraceLog();

class TraceLog {
  static const int maxEvents = 60;
  final List<String> _events = <String>[];
  final List<Duration> _times = <Duration>[];
  final Stopwatch _clock = Stopwatch()..start();

  List<(Duration, String)> get events => <(Duration, String)>[
        for (int i = 0; i < _events.length; i++) (_times[i], _events[i]),
      ];

  void log(String message) {
    if (!kTraceAdd) return;
    final Duration t = _clock.elapsed;
    _events.add(message);
    _times.add(t);
    if (_events.length > maxEvents) {
      _events.removeAt(0);
      _times.removeAt(0);
    }
    // Also emit to the platform log so logcat captures it.
    // ignore: avoid_print
    print('TASKFLOW-TRACE ${t.inMilliseconds}ms $message');
  }
}