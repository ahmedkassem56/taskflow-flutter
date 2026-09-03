/// Inline quick-add composer (DESIGN.md §7 parity with the JS composer).
///
/// Always visible under the item list. Type a title, press Enter (or the send
/// button) and the task is created instantly: the field clears and refocuses,
/// so adding many entries in a row is type → Enter → type → Enter with no
/// modal round-trip. Advanced fields (priority, due date, quantity,
/// recurrence) live in the row's edit sheet — set them once per item, not per
/// keystroke. The optional list picker (All view, >1 list) chooses the target
/// list; in a list view the target is fixed.
library;

import 'package:flutter/material.dart';

import '../../../../data/models/task_list.dart';

class QuickAddBar extends StatefulWidget {
  const QuickAddBar({
    super.key,
    required this.lists,
    required this.selectedListId,
    required this.showListPicker,
    required this.onListChanged,
    required this.onSubmit,
    this.enabled = true,
  });

  /// Available lists; the composer is disabled when this is empty.
  final List<TaskList> lists;

  /// The list new tasks are added to right now.
  final int selectedListId;

  /// Whether the list picker is shown (All view with more than one list).
  final bool showListPicker;

  final ValueChanged<int> onListChanged;

  /// Creates the task. Returns an error message to toast on failure, or null
  /// on success (the caller then clears + refocuses the field).
  final Future<String?> Function(String title) onSubmit;

  final bool enabled;

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !widget.enabled) return;
    final String title = _controller.text.trim();
    if (title.isEmpty) return;
    setState(() => _busy = true);
    String? error;
    try {
      error = await widget.onSubmit(title);
    } catch (e) {
      error = '$e';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      _controller.clear();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
    // The field is never disabled, so focus (and the mobile keyboard) is
    // retained through the whole add. Re-assert focus next frame as cheap
    // insurance against IMEs that dismiss on the send action.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    TaskList? selected;
    for (final TaskList l in widget.lists) {
      if (l.id == widget.selectedListId) {
        selected = l;
        break;
      }
    }

    final Widget field = TextField(
      key: const Key('quick-add-field'),
      controller: _controller,
      focusNode: _focusNode,
      // NOTE: never disable while busy — disabling a focused field drops focus
      // and closes the mobile keyboard mid-flow. _submit guards re-entry.
      enabled: widget.enabled,
      textInputAction: TextInputAction.send,
      onSubmitted: (String _) => _submit(),
      decoration: InputDecoration(
        hintText: !widget.enabled
            ? 'Create a list first'
            : (selected != null ? 'Add to “${selected.name}”…' : 'Add a task…'),
        prefixIcon: const Icon(Icons.add, size: 20),
        isDense: true,
        suffixIcon: _busy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                key: const Key('quick-add-submit'),
                tooltip: 'Add task',
                icon: const Icon(Icons.send, size: 18),
                onPressed: widget.enabled ? _submit : null,
              ),
      ),
    );

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (widget.showListPicker && widget.lists.length > 1) ...<Widget>[
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    key: const Key('quick-add-list-picker'),
                    value: widget.selectedListId,
                    isDense: true,
                    items: <DropdownMenuItem<int>>[
                      for (final TaskList l in widget.lists)
                        DropdownMenuItem<int>(value: l.id, child: Text(l.name)),
                    ],
                    onChanged: widget.enabled
                        ? (int? id) {
                            if (id != null) widget.onListChanged(id);
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(child: field),
            ],
          ),
        ),
      ),
    );
  }
}
