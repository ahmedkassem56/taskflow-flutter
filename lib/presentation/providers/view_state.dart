import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_state.freezed.dart';

/// App-wide navigation mode (DESIGN.md §5 state machine).
///
/// * [ViewMode.app] — personal lists/items (HomeShell / AppView).
/// * [ViewMode.share] — a shared list page (`/share/<token>`).
enum ViewMode { app, share }

/// What the app-mode items view shows (DESIGN.md §5):
/// * [TaskView.all] — every list ("All tasks"); never reorderable.
/// * [TaskView.list] — one list by id.
@freezed
abstract class TaskView with _$TaskView {
  const factory TaskView.all() = _TaskViewAll;
  const factory TaskView.list(int id) = _TaskViewList;
}

/// Current view state (DESIGN.md §5): mode + app-mode selection.
///
/// Only the app-mode selection is persisted (`taskflow.view`: `'all'` or the
/// list id); share mode is transient, driven by the share URL/route.
@freezed
abstract class ViewState with _$ViewState {
  const factory ViewState({
    required ViewMode mode,
    required TaskView view,
  }) = _ViewState;
}
