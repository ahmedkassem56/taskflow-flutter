import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/task_list.dart';
import '../../data/services/settings_store.dart';
import 'items.dart';
import 'lists.dart';
import 'share_controller.dart';
import 'view_state.dart';

export 'view_state.dart';

part 'view_controller.g.dart';

/// View selection + mode controller (DESIGN.md §5).
///
/// * Holds the app-mode selection (All | list id) and the app/share mode.
/// * Persists the selection under `taskflow.view` (`'all'` or the list id)
///   and restores it at boot — but only when that list still exists, else
///   All (validation runs against every `listsController` refresh; if the
///   current list vanishes the view drops back to All).
/// * Hosts the UI bookkeeping flags that suppress polling while a modal is
///   open, a drag is active, or the app is backgrounded (DESIGN.md §5.2) —
///   both item-polling controllers read them here so there is a single
///   source of truth.
@Riverpod(keepAlive: true)
class ViewController extends _$ViewController {
  static const String prefsKey = 'taskflow.view';

  ViewMode _mode = ViewMode.app;
  int? _selectedListId; // null => All
  bool _restoreAttempted = false;

  // Poll-suppression flags (DESIGN.md §5.2), read by Items/Share controllers.
  bool _dialogOpen = false;
  bool _rearrangeActive = false;
  bool _pointerDown = false;
  bool _appVisible = true;

  @override
  ViewState build() {
    // Re-derive after every lists refresh: a vanished current list falls
    // back to All (DESIGN.md §5 view transitions).
    ref.watch(listsControllerProvider);
    _attemptRestore();
    return _compose();
  }

  // -- polling flag API (UI bookkeeping; suppressed poll conditions) ----------

  bool get dialogOpen => _dialogOpen;
  bool get rearrangeActive => _rearrangeActive;
  bool get pointerDown => _pointerDown;
  bool get appVisible => _appVisible;

  /// Any modal / bottom sheet / dialog is open — polls pause.
  void setDialogOpen(bool value) => _dialogOpen = value;

  /// A reorder drag is in progress (onReorderStart/End) — polls pause.
  void setRearrangeActive(bool value) => _rearrangeActive = value;

  /// A pointer is down on the list (drag/scroll gesture) — polls pause.
  void setPointerDown(bool value) => _pointerDown = value;

  /// App lifecycle visibility (hidden tab / backgrounded app). Fires one
  /// immediate refresh tick when the app becomes visible again.
  void setAppVisible(bool value) {
    final bool wasVisible = _appVisible;
    _appVisible = value;
    if (value && !wasVisible) {
      final ViewMode mode = _mode;
      if (mode == ViewMode.app) {
        ref.read(itemsControllerProvider.notifier).pollNow();
      } else {
        ref.read(shareControllerProvider.notifier).pollNow();
      }
    }
  }

  // -- selection API -----------------------------------------------------------

  /// Switches to the All view (app mode) and persists it.
  void selectAll() {
    if (_mode != ViewMode.app) return;
    _selectedListId = null;
    SettingsStore.write(prefsKey, 'all');
    state = _compose();
  }

  /// Switches to the single-list view (app mode) and persists it.
  void selectList(int listId) {
    if (_mode != ViewMode.app) return;
    _selectedListId = listId;
    SettingsStore.write(prefsKey, '$listId');
    state = _compose();
  }

  /// Enters share mode (called by the share route / router integration).
  void enterShareMode() {
    if (_mode == ViewMode.share) return;
    _mode = ViewMode.share;
    state = _compose();
  }

  /// Leaves share mode back to the previously selected app view.
  void exitShareMode() {
    if (_mode != ViewMode.share) return;
    _mode = ViewMode.app;
    state = _compose();
  }

  /// Clears the persisted selection (e.g. the stored list was deleted).
  void resetToAll() {
    _selectedListId = null;
    SettingsStore.write(prefsKey, 'all');
    state = _compose();
  }

  // -- internals ---------------------------------------------------------------

  ViewState _compose() {
    _dropVanishedSelection();
    return ViewState(
      mode: _mode,
      view: (_mode == ViewMode.app && _selectedListId != null)
          ? TaskView.list(_selectedListId!)
          : const TaskView.all(),
    );
  }

  /// If the selected list no longer exists in the latest lists snapshot,
  /// fall back to All (DESIGN.md §5: "after every lists refresh, if the
  /// current listId vanished → switch to All").
  void _dropVanishedSelection() {
    final int? selected = _selectedListId;
    if (selected == null) return;
    final List<TaskList>? lists =
        ref.read(listsControllerProvider).value;
    if (lists == null) return; // lists not loaded yet — hold the selection
    for (final TaskList list in lists) {
      if (list.id == selected) return;
    }
    _selectedListId = null;
    SettingsStore.write(prefsKey, 'all');
  }

  /// Restores the persisted selection once per controller lifetime. The
  /// existence check runs via [_dropVanishedSelection] whenever lists data
  /// arrives or refreshes.
  Future<void> _attemptRestore() async {
    if (_restoreAttempted) return;
    _restoreAttempted = true;
    try {
      final String? raw = await SettingsStore.read(prefsKey);
      if (raw == null || raw == 'all' || !ref.mounted) return;
      final int? id = int.tryParse(raw);
      if (id == null || !ref.mounted) return;
      _selectedListId = id;
      // Lists may already be loaded (build raced) — validate immediately.
      _dropVanishedSelection();
      if (ref.mounted) state = _compose();
    } catch (_) {
      // Never crash on persistence failures.
    }
  }
}
