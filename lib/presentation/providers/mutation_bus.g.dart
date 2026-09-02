// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mutation_bus.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global mutation bookkeeping (DESIGN.md §5.2/§5.3):
///
/// * `state` = number of mutations currently in flight (`mutating`). UI
///   disables optimistic rows while `> 0`; poll ticks skip while `> 0`.
/// * `gen` (not part of the exposed state) — a monotonically increasing
///   staleness generation. Every fetch captures `gen` when it starts and is
///   **discarded** when it completes if `gen` moved meanwhile (a mutation or
///   view switch started while it was in flight — the newer operation's
///   optimistic state must win until its own settle refresh).

@ProviderFor(MutationBus)
final mutationBusProvider = MutationBusProvider._();

/// Global mutation bookkeeping (DESIGN.md §5.2/§5.3):
///
/// * `state` = number of mutations currently in flight (`mutating`). UI
///   disables optimistic rows while `> 0`; poll ticks skip while `> 0`.
/// * `gen` (not part of the exposed state) — a monotonically increasing
///   staleness generation. Every fetch captures `gen` when it starts and is
///   **discarded** when it completes if `gen` moved meanwhile (a mutation or
///   view switch started while it was in flight — the newer operation's
///   optimistic state must win until its own settle refresh).
final class MutationBusProvider extends $NotifierProvider<MutationBus, int> {
  /// Global mutation bookkeeping (DESIGN.md §5.2/§5.3):
  ///
  /// * `state` = number of mutations currently in flight (`mutating`). UI
  ///   disables optimistic rows while `> 0`; poll ticks skip while `> 0`.
  /// * `gen` (not part of the exposed state) — a monotonically increasing
  ///   staleness generation. Every fetch captures `gen` when it starts and is
  ///   **discarded** when it completes if `gen` moved meanwhile (a mutation or
  ///   view switch started while it was in flight — the newer operation's
  ///   optimistic state must win until its own settle refresh).
  MutationBusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mutationBusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mutationBusHash();

  @$internal
  @override
  MutationBus create() => MutationBus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$mutationBusHash() => r'86bcb7001eb6e0813eb2b93514340c41f917dcec';

/// Global mutation bookkeeping (DESIGN.md §5.2/§5.3):
///
/// * `state` = number of mutations currently in flight (`mutating`). UI
///   disables optimistic rows while `> 0`; poll ticks skip while `> 0`.
/// * `gen` (not part of the exposed state) — a monotonically increasing
///   staleness generation. Every fetch captures `gen` when it starts and is
///   **discarded** when it completes if `gen` moved meanwhile (a mutation or
///   view switch started while it was in flight — the newer operation's
///   optimistic state must win until its own settle refresh).

abstract class _$MutationBus extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
