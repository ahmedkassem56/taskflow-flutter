import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mutation_bus.g.dart';

/// Global mutation bookkeeping (DESIGN.md §5.2/§5.3):
///
/// * `state` = number of mutations currently in flight (`mutating`). UI
///   disables optimistic rows while `> 0`; poll ticks skip while `> 0`.
/// * `gen` (not part of the exposed state) — a monotonically increasing
///   staleness generation. Every fetch captures `gen` when it starts and is
///   **discarded** when it completes if `gen` moved meanwhile (a mutation or
///   view switch started while it was in flight — the newer operation's
///   optimistic state must win until its own settle refresh).
@Riverpod(keepAlive: true)
class MutationBus extends _$MutationBus {
  int _gen = 0;

  @override
  int build() => 0;

  /// Current staleness generation.
  int get gen => _gen;

  /// Marks a mutation start: bumps the generation (invalidating in-flight
  /// reads) and increments the in-flight counter.
  void begin() {
    _gen++;
    state = state + 1;
  }

  /// Marks a mutation end (never below zero). Also bumps the generation so a
  /// fetch that started *after* the mutation (e.g. the next 5s poll) sees a
  /// changed gen at completion and discards itself — otherwise it could apply
  /// stale pre-commit data right after the create's settle (the cause of the
  /// Android add blink: create DONE at 15900, stale poll 'fetch OK 73' at
  /// 15920 clobbered 74->73).
  void end() {
    if (state > 0) {
      _gen++;
      state = state - 1;
    }
  }

  /// Bumps the generation without starting a mutation (used on view switches
  /// so an in-flight fetch for the old view is discarded).
  void touch() {
    _gen++;
  }
}
