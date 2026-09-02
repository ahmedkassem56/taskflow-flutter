// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'share_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShareLink {

 String get token; String get permission; String get url;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShareLinkCopyWith<ShareLink> get copyWith => _$ShareLinkCopyWithImpl<ShareLink>(this as ShareLink, _$identity);

  /// Serializes this ShareLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShareLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShareLink&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.permission, _this.permission) || other.permission == _this.permission)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShareLink;
  return Object.hash(runtimeType,_this.token,_this.permission,_this.url,_this.createdAt);
}

@override
String toString() {
  final _this = this as ShareLink;
  return 'ShareLink(token: ${_this.token}, permission: ${_this.permission}, url: ${_this.url}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ShareLinkCopyWith<$Res>  {
  factory $ShareLinkCopyWith(ShareLink value, $Res Function(ShareLink) _then) = _$ShareLinkCopyWithImpl;
@useResult
$Res call({
 String token, String permission, String url,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$ShareLinkCopyWithImpl<$Res>
    implements $ShareLinkCopyWith<$Res> {
  _$ShareLinkCopyWithImpl(this._self, this._then);

  final ShareLink _self;
  final $Res Function(ShareLink) _then;

/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? permission = null,Object? url = null,Object? createdAt = null,}) {
  return _then(ShareLink(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ShareLink].
extension ShareLinkPatterns on ShareLink {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShareLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShareLink value)  $default,){
final _that = this;
switch (_that) {
case _ShareLink():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShareLink value)?  $default,){
final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String permission,  String url, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
return $default(_that.token,_that.permission,_that.url,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String permission,  String url, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ShareLink():
return $default(_that.token,_that.permission,_that.url,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String permission,  String url, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
return $default(_that.token,_that.permission,_that.url,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShareLink implements ShareLink {
  const _ShareLink({required this.token, required this.permission, required this.url, @JsonKey(name: 'created_at') required this.createdAt});
  factory _ShareLink.fromJson(Map<String, dynamic> json) => _$ShareLinkFromJson(json);

@override final  String token;
@override final  String permission;
@override final  String url;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShareLinkCopyWith<_ShareLink> get copyWith => __$ShareLinkCopyWithImpl<_ShareLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShareLinkToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShareLink&&(identical(other.token, token) || other.token == token)&&(identical(other.permission, permission) || other.permission == permission)&&(identical(other.url, url) || other.url == url)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,token,permission,url,createdAt);
}

@override
String toString() {
    return 'ShareLink(token: $token, permission: $permission, url: $url, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ShareLinkCopyWith<$Res> implements $ShareLinkCopyWith<$Res> {
  factory _$ShareLinkCopyWith(_ShareLink value, $Res Function(_ShareLink) _then) = __$ShareLinkCopyWithImpl;
@override @useResult
$Res call({
 String token, String permission, String url,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$ShareLinkCopyWithImpl<$Res>
    implements _$ShareLinkCopyWith<$Res> {
  __$ShareLinkCopyWithImpl(this._self, this._then);

  final _ShareLink _self;
  final $Res Function(_ShareLink) _then;

/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? permission = null,Object? url = null,Object? createdAt = null,}) {
  return _then(_ShareLink(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
