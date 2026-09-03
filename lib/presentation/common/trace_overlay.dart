/// Debug overlay that renders the in-app trace log (build with
/// `--dart-define=TRACE_ADD=true`), so a real device screenshot shows exactly
/// what state transitions happened around a quick-add.
library;

import 'package:flutter/material.dart';

import '../../core/trace_log.dart';

/// A small translucent panel listing recent [traceLog] events, newest last.
/// Place it over the app (e.g. in a Stack) when debugging the add race.
class TraceOverlay extends StatelessWidget {
  const TraceOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kTraceAdd) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        key: const Key('trace-overlay'),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: const BoxConstraints(maxHeight: 180),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          reverse: true,
          itemCount: traceLog.events.length,
          itemBuilder: (BuildContext context, int index) {
            final (Duration t, String msg) =
                traceLog.events[traceLog.events.length - 1 - index];
            return Text(
              '${t.inMilliseconds}ms  $msg',
              style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 10),
            );
          },
        ),
      ),
    );
  }
}