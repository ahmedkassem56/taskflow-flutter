// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShareLink _$ShareLinkFromJson(Map<String, dynamic> json) => _ShareLink(
  token: json['token'] as String,
  permission: json['permission'] as String,
  url: json['url'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ShareLinkToJson(_ShareLink instance) =>
    <String, dynamic>{
      'token': instance.token,
      'permission': instance.permission,
      'url': instance.url,
      'created_at': instance.createdAt.toIso8601String(),
    };
