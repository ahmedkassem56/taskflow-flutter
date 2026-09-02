// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItemEnvelope _$ItemEnvelopeFromJson(Map<String, dynamic> json) =>
    _ItemEnvelope(
      item: TaskItem.fromJson(json['item'] as Map<String, dynamic>),
      spawned: json['spawned'] == null
          ? null
          : TaskItem.fromJson(json['spawned'] as Map<String, dynamic>),
      swapped: json['swapped'] == null
          ? null
          : TaskItem.fromJson(json['swapped'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ItemEnvelopeToJson(_ItemEnvelope instance) =>
    <String, dynamic>{
      'item': instance.item,
      'spawned': instance.spawned,
      'swapped': instance.swapped,
    };
