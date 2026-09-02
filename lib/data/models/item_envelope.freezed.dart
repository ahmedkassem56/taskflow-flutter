// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_envelope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItemEnvelope {

 TaskItem get item; TaskItem? get spawned; TaskItem? get swapped;
/// Create a copy of ItemEnvelope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemEnvelopeCopyWith<ItemEnvelope> get copyWith => _$ItemEnvelopeCopyWithImpl<ItemEnvelope>(this as ItemEnvelope, _$identity);

  /// Serializes this ItemEnvelope to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ItemEnvelope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemEnvelope&&(identical(other.item, _this.item) || other.item == _this.item)&&(identical(other.spawned, _this.spawned) || other.spawned == _this.spawned)&&(identical(other.swapped, _this.swapped) || other.swapped == _this.swapped));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ItemEnvelope;
  return Object.hash(runtimeType,_this.item,_this.spawned,_this.swapped);
}

@override
String toString() {
  final _this = this as ItemEnvelope;
  return 'ItemEnvelope(item: ${_this.item}, spawned: ${_this.spawned}, swapped: ${_this.swapped})';
}


}

/// @nodoc
abstract mixin class $ItemEnvelopeCopyWith<$Res>  {
  factory $ItemEnvelopeCopyWith(ItemEnvelope value, $Res Function(ItemEnvelope) _then) = _$ItemEnvelopeCopyWithImpl;
@useResult
$Res call({
 TaskItem item, TaskItem? spawned, TaskItem? swapped
});


$TaskItemCopyWith<$Res> get item;$TaskItemCopyWith<$Res>? get spawned;$TaskItemCopyWith<$Res>? get swapped;

}
/// @nodoc
class _$ItemEnvelopeCopyWithImpl<$Res>
    implements $ItemEnvelopeCopyWith<$Res> {
  _$ItemEnvelopeCopyWithImpl(this._self, this._then);

  final ItemEnvelope _self;
  final $Res Function(ItemEnvelope) _then;

/// Create a copy of ItemEnvelope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? item = null,Object? spawned = freezed,Object? swapped = freezed,}) {
  return _then(ItemEnvelope(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as TaskItem,spawned: freezed == spawned ? _self.spawned : spawned // ignore: cast_nullable_to_non_nullable
as TaskItem?,swapped: freezed == swapped ? _self.swapped : swapped // ignore: cast_nullable_to_non_nullable
as TaskItem?,
  ));
}
/// Create a copy of ItemEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskItemCopyWith<$Res> get item {
  
  return $TaskItemCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}/// Create a copy of ItemEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskItemCopyWith<$Res>? get spawned {
    if (_self.spawned == null) {
    return null;
  }

  return $TaskItemCopyWith<$Res>(_self.spawned!, (value) {
    return _then(_self.copyWith(spawned: value));
  });
}/// Create a copy of ItemEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskItemCopyWith<$Res>? get swapped {
    if (_self.swapped == null) {
    return null;
  }

  return $TaskItemCopyWith<$Res>(_self.swapped!, (value) {
    return _then(_self.copyWith(swapped: value));
  });
}
}


/// Adds pattern-matching-related methods to [ItemEnvelope].
extension ItemEnvelopePatterns on ItemEnvelope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemEnvelope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemEnvelope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemEnvelope value)  $default,){
final _that = this;
switch (_that) {
case _ItemEnvelope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemEnvelope value)?  $default,){
final _that = this;
switch (_that) {
case _ItemEnvelope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TaskItem item,  TaskItem? spawned,  TaskItem? swapped)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemEnvelope() when $default != null:
return $default(_that.item,_that.spawned,_that.swapped);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TaskItem item,  TaskItem? spawned,  TaskItem? swapped)  $default,) {final _that = this;
switch (_that) {
case _ItemEnvelope():
return $default(_that.item,_that.spawned,_that.swapped);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TaskItem item,  TaskItem? spawned,  TaskItem? swapped)?  $default,) {final _that = this;
switch (_that) {
case _ItemEnvelope() when $default != null:
return $default(_that.item,_that.spawned,_that.swapped);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemEnvelope implements ItemEnvelope {
  const _ItemEnvelope({required this.item, this.spawned, this.swapped});
  factory _ItemEnvelope.fromJson(Map<String, dynamic> json) => _$ItemEnvelopeFromJson(json);

@override final  TaskItem item;
@override final  TaskItem? spawned;
@override final  TaskItem? swapped;

/// Create a copy of ItemEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemEnvelopeCopyWith<_ItemEnvelope> get copyWith => __$ItemEnvelopeCopyWithImpl<_ItemEnvelope>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemEnvelopeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemEnvelope&&(identical(other.item, item) || other.item == item)&&(identical(other.spawned, spawned) || other.spawned == spawned)&&(identical(other.swapped, swapped) || other.swapped == swapped));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,item,spawned,swapped);
}

@override
String toString() {
    return 'ItemEnvelope(item: $item, spawned: $spawned, swapped: $swapped)';
}


}

/// @nodoc
abstract mixin class _$ItemEnvelopeCopyWith<$Res> implements $ItemEnvelopeCopyWith<$Res> {
  factory _$ItemEnvelopeCopyWith(_ItemEnvelope value, $Res Function(_ItemEnvelope) _then) = __$ItemEnvelopeCopyWithImpl;
@override @useResult
$Res call({
 TaskItem item, TaskItem? spawned, TaskItem? swapped
});


@override $TaskItemCopyWith<$Res> get item;@override $TaskItemCopyWith<$Res>? get spawned;@override $TaskItemCopyWith<$Res>? get swapped;

}
/// @nodoc
class __$ItemEnvelopeCopyWithImpl<$Res>
    implements _$ItemEnvelopeCopyWith<$Res> {
  __$ItemEnvelopeCopyWithImpl(this._self, this._then);

  final _ItemEnvelope _self;
  final $Res Function(_ItemEnvelope) _then;

/// Create a copy of ItemEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? item = null,Object? spawned = freezed,Object? swapped = freezed,}) {
  return _then(_ItemEnvelope(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as TaskItem,spawned: freezed == spawned ? _self.spawned : spawned // ignore: cast_nullable_to_non_nullable
as TaskItem?,swapped: freezed == swapped ? _self.swapped : swapped // ignore: cast_nullable_to_non_nullable
as TaskItem?,
  ));
}

/// Create a copy of ItemEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskItemCopyWith<$Res> get item {
  
  return $TaskItemCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}/// Create a copy of ItemEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskItemCopyWith<$Res>? get spawned {
    if (_self.spawned == null) {
    return null;
  }

  return $TaskItemCopyWith<$Res>(_self.spawned!, (value) {
    return _then(_self.copyWith(spawned: value));
  });
}/// Create a copy of ItemEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskItemCopyWith<$Res>? get swapped {
    if (_self.swapped == null) {
    return null;
  }

  return $TaskItemCopyWith<$Res>(_self.swapped!, (value) {
    return _then(_self.copyWith(swapped: value));
  });
}
}

// dart format on
