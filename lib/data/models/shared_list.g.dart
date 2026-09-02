// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SharedList _$SharedListFromJson(Map<String, dynamic> json) => _SharedList(
  list: TaskList.fromJson(json['list'] as Map<String, dynamic>),
  items: (json['items'] as List<dynamic>)
      .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  permission: json['permission'] as String,
);

Map<String, dynamic> _$SharedListToJson(_SharedList instance) =>
    <String, dynamic>{
      'list': instance.list,
      'items': instance.items,
      'permission': instance.permission,
    };
