// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SharedList {

 TaskList get list; List<TaskItem> get items; String get permission;
/// Create a copy of SharedList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedListCopyWith<SharedList> get copyWith => _$SharedListCopyWithImpl<SharedList>(this as SharedList, _$identity);

  /// Serializes this SharedList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SharedList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedList&&(identical(other.list, _this.list) || other.list == _this.list)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.permission, _this.permission) || other.permission == _this.permission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SharedList;
  return Object.hash(runtimeType,_this.list,const DeepCollectionEquality().hash(_this.items),_this.permission);
}

@override
String toString() {
  final _this = this as SharedList;
  return 'SharedList(list: ${_this.list}, items: ${_this.items}, permission: ${_this.permission})';
}


}

/// @nodoc
abstract mixin class $SharedListCopyWith<$Res>  {
  factory $SharedListCopyWith(SharedList value, $Res Function(SharedList) _then) = _$SharedListCopyWithImpl;
@useResult
$Res call({
 TaskList list, List<TaskItem> items, String permission
});


$TaskListCopyWith<$Res> get list;

}
/// @nodoc
class _$SharedListCopyWithImpl<$Res>
    implements $SharedListCopyWith<$Res> {
  _$SharedListCopyWithImpl(this._self, this._then);

  final SharedList _self;
  final $Res Function(SharedList) _then;

/// Create a copy of SharedList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? list = null,Object? items = null,Object? permission = null,}) {
  return _then(SharedList(
list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as TaskList,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TaskItem>,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SharedList
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskListCopyWith<$Res> get list {
  
  return $TaskListCopyWith<$Res>(_self.list, (value) {
    return _then(_self.copyWith(list: value));
  });
}
}


/// Adds pattern-matching-related methods to [SharedList].
extension SharedListPatterns on SharedList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SharedList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SharedList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SharedList value)  $default,){
final _that = this;
switch (_that) {
case _SharedList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SharedList value)?  $default,){
final _that = this;
switch (_that) {
case _SharedList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TaskList list,  List<TaskItem> items,  String permission)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SharedList() when $default != null:
return $default(_that.list,_that.items,_that.permission);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TaskList list,  List<TaskItem> items,  String permission)  $default,) {final _that = this;
switch (_that) {
case _SharedList():
return $default(_that.list,_that.items,_that.permission);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TaskList list,  List<TaskItem> items,  String permission)?  $default,) {final _that = this;
switch (_that) {
case _SharedList() when $default != null:
return $default(_that.list,_that.items,_that.permission);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SharedList extends SharedList {
  const _SharedList({required this.list, required  List<TaskItem> items, required this.permission}): _items = items,super._();
  factory _SharedList.fromJson(Map<String, dynamic> json) => _$SharedListFromJson(json);

@override final  TaskList list;
 final  List<TaskItem> _items;
@override List<TaskItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String permission;

/// Create a copy of SharedList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SharedListCopyWith<_SharedList> get copyWith => __$SharedListCopyWithImpl<_SharedList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SharedListToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SharedList&&(identical(other.list, list) || other.list == list)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.permission, permission) || other.permission == permission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,list,const DeepCollectionEquality().hash(_items),permission);
}

@override
String toString() {
    return 'SharedList(list: $list, items: $items, permission: $permission)';
}


}

/// @nodoc
abstract mixin class _$SharedListCopyWith<$Res> implements $SharedListCopyWith<$Res> {
  factory _$SharedListCopyWith(_SharedList value, $Res Function(_SharedList) _then) = __$SharedListCopyWithImpl;
@override @useResult
$Res call({
 TaskList list, List<TaskItem> items, String permission
});


@override $TaskListCopyWith<$Res> get list;

}
/// @nodoc
class __$SharedListCopyWithImpl<$Res>
    implements _$SharedListCopyWith<$Res> {
  __$SharedListCopyWithImpl(this._self, this._then);

  final _SharedList _self;
  final $Res Function(_SharedList) _then;

/// Create a copy of SharedList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? list = null,Object? items = null,Object? permission = null,}) {
  return _then(_SharedList(
list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as TaskList,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TaskItem>,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SharedList
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskListCopyWith<$Res> get list {
  
  return $TaskListCopyWith<$Res>(_self.list, (value) {
    return _then(_self.copyWith(list: value));
  });
}
}

// dart format on
