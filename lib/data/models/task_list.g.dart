// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskList _$TaskListFromJson(Map<String, dynamic> json) => _TaskList(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  itemCount: (json['item_count'] as num).toInt(),
  pendingCount: (json['pending_count'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TaskListToJson(_TaskList instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'item_count': instance.itemCount,
  'pending_count': instance.pendingCount,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
