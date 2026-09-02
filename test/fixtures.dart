/// Shared JSON fixtures in the exact backend envelopes (DESIGN.md §2.2).
library;

import 'package:taskflow_app/data/models/enums.dart';
import 'package:taskflow_app/data/models/task_item.dart';
import 'package:taskflow_app/data/models/task_list.dart';

String iso(int day, [int hour = 10]) =>
    '2026-09-${day.toString().padLeft(2, '0')}T${hour.toString().padLeft(2, '0')}:00:00.000000Z';

Map<String, dynamic> listJson(
  int id,
  String name, {
  int total = 0,
  int pending = 0,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'item_count': total,
    'pending_count': pending,
    'created_at': iso(1),
    'updated_at': iso(1),
  };
}

Map<String, dynamic> itemJson({
  required int id,
  required int listId,
  required String title,
  required bool done,
  int position = 0,
  String priority = 'none',
  String? notes,
  String? dueDate,
  num quantity = 1,
  String recurrence = 'none',
  int? recurrenceInterval,
  int day = 2,
}) {
  return <String, dynamic>{
    'id': id,
    'list_id': listId,
    'title': title,
    'notes': notes,
    'priority': priority,
    'due_date': dueDate,
    'quantity': quantity,
    'position': position,
    'done': done,
    'recurrence': recurrence,
    'recurrence_interval': recurrenceInterval,
    'created_at': iso(day),
    'updated_at': iso(day),
  };
}

Map<String, dynamic> envelopeJson(
  Map<String, dynamic> item, {
  Map<String, dynamic>? spawned,
  Map<String, dynamic>? swapped,
}) {
  return <String, dynamic>{
    'item': item,
    // Non-move PATCH responses always carry the `spawned` key (null when no
    // recurrence occurrence was created); `move` responses carry `swapped`.
    'spawned': spawned,
    'swapped': ?swapped,
  };
}

/// Convenience: builds a [TaskItem] model directly (for pure math tests).
TaskItem item({
  required int id,
  int listId = 1,
  String title = 'task',
  bool done = false,
  int position = 0,
  Priority priority = Priority.none,
  String? notes,
  String? dueDate,
  num quantity = 1,
  Recurrence recurrence = Recurrence.none,
  int? recurrenceInterval,
}) {
  return TaskItem(
    id: id,
    listId: listId,
    title: title,
    notes: notes,
    priority: priority,
    dueDate: dueDate,
    quantity: quantity,
    position: position,
    done: done,
    recurrence: recurrence,
    recurrenceInterval: recurrenceInterval,
    createdAt: DateTime.utc(2026, 9, 2, 10),
    updatedAt: DateTime.utc(2026, 9, 2, 10),
  );
}

TaskList listModel(int id, String name) => TaskList.fromJson(listJson(id, name));

/// Parses a JSON map into a [TaskItem] (round-trip convenience).
TaskItem itemFromJson(Map<String, dynamic> json) => TaskItem.fromJson(json);
