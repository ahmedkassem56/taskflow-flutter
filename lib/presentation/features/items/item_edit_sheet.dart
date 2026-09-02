/// Create/edit task bottom sheet (DESIGN.md §6 + §7).
///
/// The sheet only collects and validates fields; mutations are delegated to
/// the caller through [showItemEditSheet]'s `onSave`/`onDelete` callbacks so
/// the app-mode and share-mode callers can route to their own controllers.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/task_item.dart';
import '../../../data/models/task_list.dart';
import '../../common/format.dart';

/// Resolved form values handed back to the caller on save.
class ItemDraft {
  const ItemDraft({
    required this.listId,
    required this.title,
    required this.notes,
    required this.priority,
    required this.dueDate,
    required this.quantity,
    required this.recurrence,
    required this.recurrenceInterval,
  });

  final int listId;
  final String title;

  /// Empty string is normalized to null by the caller before sending.
  final String notes;
  final Priority priority;
  final String? dueDate;
  final num quantity;
  final Recurrence recurrence;
  final int? recurrenceInterval;
}

/// Opens the item edit sheet.
///
/// * [item] non-null edits that item; null creates a new task.
/// * [lists] is the source for the list picker; the picker is only rendered
///   when [showListPicker] is true (All view in app mode). In list/share
///   views [initialListId] is fixed and no picker is shown.
/// * [onSave] receives the draft and returns an error message on failure or
///   null on success; the sheet stays open on failure and shows the message.
/// * [onDelete] (edit mode only) is awaited after a destructive confirm.
///
/// Returns the saved [TaskItem]-free draft via `pop` on success.
Future<ItemDraft?> showItemEditSheet(
  BuildContext context, {
  required TaskItem? item,
  required List<TaskList> lists,
  required int initialListId,
  required bool showListPicker,
  required Future<String?> Function(ItemDraft draft) onSave,
  Future<void> Function()? onDelete,
}) {
  return showModalBottomSheet<ItemDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return _ItemEditSheet(
        item: item,
        lists: lists,
        initialListId: initialListId,
        showListPicker: showListPicker,
        onSave: onSave,
        onDelete: onDelete,
      );
    },
  );
}

class _ItemEditSheet extends StatefulWidget {
  const _ItemEditSheet({
    required this.item,
    required this.lists,
    required this.initialListId,
    required this.showListPicker,
    required this.onSave,
    this.onDelete,
  });

  final TaskItem? item;
  final List<TaskList> lists;
  final int initialListId;
  final bool showListPicker;
  final Future<String?> Function(ItemDraft draft) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<_ItemEditSheet> createState() => _ItemEditSheetState();
}

class _ItemEditSheetState extends State<_ItemEditSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _quantityController;
  late final TextEditingController _intervalController;

  late int _listId;
  late Priority _priority;
  String? _dueDate;
  late Recurrence _recurrence;
  bool _saving = false;

  bool get _isCreate => widget.item == null;

  @override
  void initState() {
    super.initState();
    final TaskItem? item = widget.item;
    _listId = item?.listId ?? widget.initialListId;
    _priority = item?.priority ?? Priority.none;
    _dueDate = item?.dueDate;
    _recurrence = item?.recurrence ?? Recurrence.none;
    _titleController = TextEditingController(text: item?.title ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _quantityController = TextEditingController(
      text: item == null ? '1' : formatQuantity(item.quantity),
    );
    _intervalController = TextEditingController(
      text: item?.recurrenceInterval == null
          ? '1'
          : '${item!.recurrenceInterval}',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _dueDate == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime.parse(_dueDate!);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
      helpText: 'Due date',
    );
    if (picked == null) return;
    setState(() {
      _dueDate = DateFormat('yyyy-MM-dd').format(picked);
    });
  }

  void _clearDueDate() {
    setState(() {
      _dueDate = null;
    });
  }

  void _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String intervalText = _intervalController.text.trim();
    final int? interval =
        _recurrence == Recurrence.custom && intervalText.isNotEmpty
            ? int.tryParse(intervalText)
            : null;
    if (_recurrence == Recurrence.custom &&
        (interval == null || interval < 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repeat interval must be at least 1 day')),
      );
      return;
    }

    final num quantity = num.parse(_quantityController.text.trim());

    final ItemDraft draft = ItemDraft(
      listId: _listId,
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      quantity: quantity,
      recurrence: _recurrence,
      recurrenceInterval: interval,
    );

    setState(() {
      _saving = true;
    });
    final String? error = await widget.onSave(draft);
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    Navigator.of(context).pop(draft);
  }

  Future<void> _delete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: Text('"${widget.item!.title}" will be permanently deleted.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    setState(() {
      _saving = true;
    });
    try {
      await widget.onDelete?.call();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TaskItem? item = widget.item;
    final bool showListPicker =
        widget.showListPicker && widget.lists.length > 1;

    final List<int> listIds = widget.lists.map((TaskList l) => l.id).toList();
    if (!listIds.contains(_listId) && listIds.isNotEmpty) {
      _listId = listIds.first;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _isCreate ? 'New task' : 'Edit task',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (showListPicker) ...<Widget>[
                DropdownButtonFormField<int>(
                  initialValue: listIds.contains(_listId) ? _listId : null,
                  decoration: const InputDecoration(
                    labelText: 'List',
                    prefixIcon: Icon(Icons.list_alt_outlined, size: 20),
                  ),
                  items: <DropdownMenuItem<int>>[
                    for (final TaskList l in widget.lists)
                      DropdownMenuItem<int>(value: l.id, child: Text(l.name)),
                  ],
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() {
                        _listId = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                key: const Key('item-title-field'),
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What needs doing?',
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due date',
                        prefixIcon: Icon(Icons.event_outlined, size: 20),
                      ),
                      child: InkWell(
                        key: const Key('item-due-picker'),
                        onTap: _pickDueDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  _dueDate == null
                                      ? 'No due date'
                                      : dueLabel(_dueDate),
                                  style: TextStyle(
                                    color: _dueDate == null
                                        ? scheme.onSurfaceVariant
                                        : scheme.onSurface,
                                  ),
                                ),
                              ),
                              if (_dueDate != null)
                                IconButton(
                                  tooltip: 'Clear due date',
                                  icon: const Icon(Icons.close, size: 16),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _clearDueDate,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('item-quantity-field'),
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixText: 'x ',
                      ),
                      validator: (String? value) {
                        final num? parsed =
                            value == null ? null : num.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<Priority>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.flag_outlined, size: 20),
                      ),
                      items: <DropdownMenuItem<Priority>>[
                        for (final Priority p in Priority.values)
                          DropdownMenuItem<Priority>(
                            value: p,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: priorityChipColor(p) ??
                                        scheme.onSurfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(priorityLabel(p) ?? 'None'),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (Priority? value) {
                        if (value != null) {
                          setState(() {
                            _priority = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Recurrence>(
                      initialValue: _recurrence,
                      decoration: const InputDecoration(
                        labelText: 'Repeats',
                        prefixIcon: Icon(Icons.repeat, size: 20),
                      ),
                      items: <DropdownMenuItem<Recurrence>>[
                        for (final Recurrence r in Recurrence.values)
                          DropdownMenuItem<Recurrence>(
                            value: r,
                            child: Text(recurrenceLabel(r, 1)),
                          ),
                      ],
                      onChanged: (Recurrence? value) {
                        if (value != null) {
                          setState(() {
                            _recurrence = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_recurrence == Recurrence.custom) ...<Widget>[
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('item-interval-field'),
                  controller: _intervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeat every N days',
                    helperText: 'Whole days between occurrences',
                  ),
                  validator: (String? value) {
                    final int? parsed =
                        value == null ? null : int.tryParse(value.trim());
                    if (parsed == null || parsed < 1) {
                      return 'Must be at least 1';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  if (item != null && widget.onDelete != null) ...<Widget>[
                    TextButton.icon(
                      onPressed: _saving ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('Delete'),
                    ),
                    const Spacer(),
                  ] else ...<Widget>[
                    const Spacer(),
                  ],
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('item-save-button'),
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isCreate ? 'Add task' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
