// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-mode lists (sidebar + counts). `AsyncValue<List<TaskList>>` — initial
/// load goes through [build] (AsyncLoading → data/error); every mutation
/// awaits the server then silently refreshes (DESIGN.md §5.3 — list ops are
/// non-optimistic).
///
/// Deleting a list while it is the current view: the lists refresh below
/// triggers the ViewController (which watches this provider) to notice the
/// vanished list and fall back to All (DESIGN.md §5 view transitions).

@ProviderFor(ListsController)
final listsControllerProvider = ListsControllerProvider._();

/// App-mode lists (sidebar + counts). `AsyncValue<List<TaskList>>` — initial
/// load goes through [build] (AsyncLoading → data/error); every mutation
/// awaits the server then silently refreshes (DESIGN.md §5.3 — list ops are
/// non-optimistic).
///
/// Deleting a list while it is the current view: the lists refresh below
/// triggers the ViewController (which watches this provider) to notice the
/// vanished list and fall back to All (DESIGN.md §5 view transitions).
final class ListsControllerProvider
    extends $AsyncNotifierProvider<ListsController, List<TaskList>> {
  /// App-mode lists (sidebar + counts). `AsyncValue<List<TaskList>>` — initial
  /// load goes through [build] (AsyncLoading → data/error); every mutation
  /// awaits the server then silently refreshes (DESIGN.md §5.3 — list ops are
  /// non-optimistic).
  ///
  /// Deleting a list while it is the current view: the lists refresh below
  /// triggers the ViewController (which watches this provider) to notice the
  /// vanished list and fall back to All (DESIGN.md §5 view transitions).
  ListsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listsControllerHash();

  @$internal
  @override
  ListsController create() => ListsController();
}

String _$listsControllerHash() => r'a7a259f005190b55ca242f951aa2aaa0dbe46e8a';

/// App-mode lists (sidebar + counts). `AsyncValue<List<TaskList>>` — initial
/// load goes through [build] (AsyncLoading → data/error); every mutation
/// awaits the server then silently refreshes (DESIGN.md §5.3 — list ops are
/// non-optimistic).
///
/// Deleting a list while it is the current view: the lists refresh below
/// triggers the ViewController (which watches this provider) to notice the
/// vanished list and fall back to All (DESIGN.md §5 view transitions).

abstract class _$ListsController extends $AsyncNotifier<List<TaskList>> {
  FutureOr<List<TaskList>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<TaskList>>, List<TaskList>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TaskList>>, List<TaskList>>,
              AsyncValue<List<TaskList>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
