// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskItem {

 int get id;@JsonKey(name: 'list_id') int get listId; String get title; String? get notes;@JsonKey(unknownEnumValue: Priority.none) Priority get priority;@JsonKey(name: 'due_date') String? get dueDate; num get quantity; int get position; bool get done;@JsonKey(unknownEnumValue: Recurrence.none) Recurrence get recurrence;@JsonKey(name: 'recurrence_interval') int? get recurrenceInterval;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of TaskItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskItemCopyWith<TaskItem> get copyWith => _$TaskItemCopyWithImpl<TaskItem>(this as TaskItem, _$identity);

  /// Serializes this TaskItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.listId, _this.listId) || other.listId == _this.listId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.done, _this.done) || other.done == _this.done)&&(identical(other.recurrence, _this.recurrence) || other.recurrence == _this.recurrence)&&(identical(other.recurrenceInterval, _this.recurrenceInterval) || other.recurrenceInterval == _this.recurrenceInterval)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskItem;
  return Object.hash(runtimeType,_this.id,_this.listId,_this.title,_this.notes,_this.priority,_this.dueDate,_this.quantity,_this.position,_this.done,_this.recurrence,_this.recurrenceInterval,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as TaskItem;
  return 'TaskItem(id: ${_this.id}, listId: ${_this.listId}, title: ${_this.title}, notes: ${_this.notes}, priority: ${_this.priority}, dueDate: ${_this.dueDate}, quantity: ${_this.quantity}, position: ${_this.position}, done: ${_this.done}, recurrence: ${_this.recurrence}, recurrenceInterval: ${_this.recurrenceInterval}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $TaskItemCopyWith<$Res>  {
  factory $TaskItemCopyWith(TaskItem value, $Res Function(TaskItem) _then) = _$TaskItemCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'list_id') int listId, String title, String? notes,@JsonKey(unknownEnumValue: Priority.none) Priority priority,@JsonKey(name: 'due_date') String? dueDate, num quantity, int position, bool done,@JsonKey(unknownEnumValue: Recurrence.none) Recurrence recurrence,@JsonKey(name: 'recurrence_interval') int? recurrenceInterval,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$TaskItemCopyWithImpl<$Res>
    implements $TaskItemCopyWith<$Res> {
  _$TaskItemCopyWithImpl(this._self, this._then);

  final TaskItem _self;
  final $Res Function(TaskItem) _then;

/// Create a copy of TaskItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? listId = null,Object? title = null,Object? notes = freezed,Object? priority = null,Object? dueDate = freezed,Object? quantity = null,Object? position = null,Object? done = null,Object? recurrence = null,Object? recurrenceInterval = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(TaskItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,recurrence: null == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as Recurrence,recurrenceInterval: freezed == recurrenceInterval ? _self.recurrenceInterval : recurrenceInterval // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskItem].
extension TaskItemPatterns on TaskItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskItem value)  $default,){
final _that = this;
switch (_that) {
case _TaskItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskItem value)?  $default,){
final _that = this;
switch (_that) {
case _TaskItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'list_id')  int listId,  String title,  String? notes, @JsonKey(unknownEnumValue: Priority.none)  Priority priority, @JsonKey(name: 'due_date')  String? dueDate,  num quantity,  int position,  bool done, @JsonKey(unknownEnumValue: Recurrence.none)  Recurrence recurrence, @JsonKey(name: 'recurrence_interval')  int? recurrenceInterval, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskItem() when $default != null:
return $default(_that.id,_that.listId,_that.title,_that.notes,_that.priority,_that.dueDate,_that.quantity,_that.position,_that.done,_that.recurrence,_that.recurrenceInterval,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'list_id')  int listId,  String title,  String? notes, @JsonKey(unknownEnumValue: Priority.none)  Priority priority, @JsonKey(name: 'due_date')  String? dueDate,  num quantity,  int position,  bool done, @JsonKey(unknownEnumValue: Recurrence.none)  Recurrence recurrence, @JsonKey(name: 'recurrence_interval')  int? recurrenceInterval, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TaskItem():
return $default(_that.id,_that.listId,_that.title,_that.notes,_that.priority,_that.dueDate,_that.quantity,_that.position,_that.done,_that.recurrence,_that.recurrenceInterval,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'list_id')  int listId,  String title,  String? notes, @JsonKey(unknownEnumValue: Priority.none)  Priority priority, @JsonKey(name: 'due_date')  String? dueDate,  num quantity,  int position,  bool done, @JsonKey(unknownEnumValue: Recurrence.none)  Recurrence recurrence, @JsonKey(name: 'recurrence_interval')  int? recurrenceInterval, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TaskItem() when $default != null:
return $default(_that.id,_that.listId,_that.title,_that.notes,_that.priority,_that.dueDate,_that.quantity,_that.position,_that.done,_that.recurrence,_that.recurrenceInterval,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskItem implements TaskItem {
  const _TaskItem({required this.id, @JsonKey(name: 'list_id') required this.listId, required this.title, this.notes, @JsonKey(unknownEnumValue: Priority.none) required this.priority, @JsonKey(name: 'due_date') this.dueDate, required this.quantity, required this.position, required this.done, @JsonKey(unknownEnumValue: Recurrence.none) required this.recurrence, @JsonKey(name: 'recurrence_interval') this.recurrenceInterval, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _TaskItem.fromJson(Map<String, dynamic> json) => _$TaskItemFromJson(json);

@override final  int id;
@override@JsonKey(name: 'list_id') final  int listId;
@override final  String title;
@override final  String? notes;
@override@JsonKey(unknownEnumValue: Priority.none) final  Priority priority;
@override@JsonKey(name: 'due_date') final  String? dueDate;
@override final  num quantity;
@override final  int position;
@override final  bool done;
@override@JsonKey(unknownEnumValue: Recurrence.none) final  Recurrence recurrence;
@override@JsonKey(name: 'recurrence_interval') final  int? recurrenceInterval;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of TaskItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskItemCopyWith<_TaskItem> get copyWith => __$TaskItemCopyWithImpl<_TaskItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskItem&&(identical(other.id, id) || other.id == id)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.position, position) || other.position == position)&&(identical(other.done, done) || other.done == done)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.recurrenceInterval, recurrenceInterval) || other.recurrenceInterval == recurrenceInterval)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,listId,title,notes,priority,dueDate,quantity,position,done,recurrence,recurrenceInterval,createdAt,updatedAt);
}

@override
String toString() {
    return 'TaskItem(id: $id, listId: $listId, title: $title, notes: $notes, priority: $priority, dueDate: $dueDate, quantity: $quantity, position: $position, done: $done, recurrence: $recurrence, recurrenceInterval: $recurrenceInterval, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskItemCopyWith<$Res> implements $TaskItemCopyWith<$Res> {
  factory _$TaskItemCopyWith(_TaskItem value, $Res Function(_TaskItem) _then) = __$TaskItemCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'list_id') int listId, String title, String? notes,@JsonKey(unknownEnumValue: Priority.none) Priority priority,@JsonKey(name: 'due_date') String? dueDate, num quantity, int position, bool done,@JsonKey(unknownEnumValue: Recurrence.none) Recurrence recurrence,@JsonKey(name: 'recurrence_interval') int? recurrenceInterval,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$TaskItemCopyWithImpl<$Res>
    implements _$TaskItemCopyWith<$Res> {
  __$TaskItemCopyWithImpl(this._self, this._then);

  final _TaskItem _self;
  final $Res Function(_TaskItem) _then;

/// Create a copy of TaskItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? listId = null,Object? title = null,Object? notes = freezed,Object? priority = null,Object? dueDate = freezed,Object? quantity = null,Object? position = null,Object? done = null,Object? recurrence = null,Object? recurrenceInterval = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TaskItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,recurrence: null == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as Recurrence,recurrenceInterval: freezed == recurrenceInterval ? _self.recurrenceInterval : recurrenceInterval // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
