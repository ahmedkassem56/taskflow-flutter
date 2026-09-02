// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskItem _$TaskItemFromJson(Map<String, dynamic> json) => _TaskItem(
  id: (json['id'] as num).toInt(),
  listId: (json['list_id'] as num).toInt(),
  title: json['title'] as String,
  notes: json['notes'] as String?,
  priority: $enumDecode(
    _$PriorityEnumMap,
    json['priority'],
    unknownValue: Priority.none,
  ),
  dueDate: json['due_date'] as String?,
  quantity: json['quantity'] as num,
  position: (json['position'] as num).toInt(),
  done: json['done'] as bool,
  recurrence: $enumDecode(
    _$RecurrenceEnumMap,
    json['recurrence'],
    unknownValue: Recurrence.none,
  ),
  recurrenceInterval: (json['recurrence_interval'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TaskItemToJson(_TaskItem instance) => <String, dynamic>{
  'id': instance.id,
  'list_id': instance.listId,
  'title': instance.title,
  'notes': instance.notes,
  'priority': _$PriorityEnumMap[instance.priority]!,
  'due_date': instance.dueDate,
  'quantity': instance.quantity,
  'position': instance.position,
  'done': instance.done,
  'recurrence': _$RecurrenceEnumMap[instance.recurrence]!,
  'recurrence_interval': instance.recurrenceInterval,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$PriorityEnumMap = {
  Priority.none: 'none',
  Priority.low: 'low',
  Priority.medium: 'medium',
  Priority.high: 'high',
};

const _$RecurrenceEnumMap = {
  Recurrence.none: 'none',
  Recurrence.daily: 'daily',
  Recurrence.weekly: 'weekly',
  Recurrence.monthly: 'monthly',
  Recurrence.custom: 'custom',
};
