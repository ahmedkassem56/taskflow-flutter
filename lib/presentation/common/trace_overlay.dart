/// Debug overlay that renders the in-app trace log (build with
/// `--dart-define=TRACE_ADD=true`), so a real device screenshot shows exactly
/// what state transitions happened around a quick-add.
///
/// Auto-refreshes on a timer so events added after the first build appear.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/trace_log.dart';

class TraceOverlay extends StatefulWidget {
  const TraceOverlay({super.key});

  @override
  State<TraceOverlay> createState() => _TraceOverlayState();
}

class _TraceOverlayState extends State<TraceOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh twice a second so newly logged events show up.
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kTraceAdd) return const SizedBox.shrink();
    final List<(Duration, String)> events = traceLog.events;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        key: const Key('trace-overlay'),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        ),
        child: events.isEmpty
            ? const Text(
                'NO TRACE EVENTS YET',
                style: TextStyle(color: Color(0xFFFFD54F), fontSize: 10),
              )
            : ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: events.length,
                itemBuilder: (BuildContext context, int index) {
                  final (Duration t, String msg) =
                      events[events.length - 1 - index];
                  return Text(
                    '${t.inMilliseconds}ms  $msg',
                    style: const TextStyle(
                        color: Color(0xFFFFD54F), fontSize: 10),
                  );
                },
              ),
      ),
    );
  }
}