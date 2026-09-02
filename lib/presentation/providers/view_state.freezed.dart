// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'view_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskView {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskView);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'TaskView()';
}


}

/// @nodoc
class $TaskViewCopyWith<$Res>  {
$TaskViewCopyWith(TaskView _, $Res Function(TaskView) __);
}


/// Adds pattern-matching-related methods to [TaskView].
extension TaskViewPatterns on TaskView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _TaskViewAll value)?  all,TResult Function( _TaskViewList value)?  list,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskViewAll() when all != null:
return all(_that);case _TaskViewList() when list != null:
return list(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _TaskViewAll value)  all,required TResult Function( _TaskViewList value)  list,}){
final _that = this;
switch (_that) {
case _TaskViewAll():
return all(_that);case _TaskViewList():
return list(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _TaskViewAll value)?  all,TResult? Function( _TaskViewList value)?  list,}){
final _that = this;
switch (_that) {
case _TaskViewAll() when all != null:
return all(_that);case _TaskViewList() when list != null:
return list(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  all,TResult Function( int id)?  list,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskViewAll() when all != null:
return all();case _TaskViewList() when list != null:
return list(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  all,required TResult Function( int id)  list,}) {final _that = this;
switch (_that) {
case _TaskViewAll():
return all();case _TaskViewList():
return list(_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  all,TResult? Function( int id)?  list,}) {final _that = this;
switch (_that) {
case _TaskViewAll() when all != null:
return all();case _TaskViewList() when list != null:
return list(_that.id);case _:
  return null;

}
}

}

/// @nodoc


class _TaskViewAll implements TaskView {
  const _TaskViewAll();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskViewAll);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'TaskView.all()';
}


}




/// @nodoc


class _TaskViewList implements TaskView {
  const _TaskViewList(this.id);
  

 final  int id;

/// Create a copy of TaskView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskViewListCopyWith<_TaskViewList> get copyWith => __$TaskViewListCopyWithImpl<_TaskViewList>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskViewList&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id);
}

@override
String toString() {
    return 'TaskView.list(id: $id)';
}


}

/// @nodoc
abstract mixin class _$TaskViewListCopyWith<$Res> implements $TaskViewCopyWith<$Res> {
  factory _$TaskViewListCopyWith(_TaskViewList value, $Res Function(_TaskViewList) _then) = __$TaskViewListCopyWithImpl;
@useResult
$Res call({
 int id
});




}
/// @nodoc
class __$TaskViewListCopyWithImpl<$Res>
    implements _$TaskViewListCopyWith<$Res> {
  __$TaskViewListCopyWithImpl(this._self, this._then);

  final _TaskViewList _self;
  final $Res Function(_TaskViewList) _then;

/// Create a copy of TaskView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_TaskViewList(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ViewState {

 ViewMode get mode; TaskView get view;
/// Create a copy of ViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ViewStateCopyWith<ViewState> get copyWith => _$ViewStateCopyWithImpl<ViewState>(this as ViewState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ViewState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ViewState&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.view, _this.view) || other.view == _this.view));
}


@override
int get hashCode {
  final _this = this as ViewState;
  return Object.hash(runtimeType,_this.mode,_this.view);
}

@override
String toString() {
  final _this = this as ViewState;
  return 'ViewState(mode: ${_this.mode}, view: ${_this.view})';
}


}

/// @nodoc
abstract mixin class $ViewStateCopyWith<$Res>  {
  factory $ViewStateCopyWith(ViewState value, $Res Function(ViewState) _then) = _$ViewStateCopyWithImpl;
@useResult
$Res call({
 ViewMode mode, TaskView view
});


$TaskViewCopyWith<$Res> get view;

}
/// @nodoc
class _$ViewStateCopyWithImpl<$Res>
    implements $ViewStateCopyWith<$Res> {
  _$ViewStateCopyWithImpl(this._self, this._then);

  final ViewState _self;
  final $Res Function(ViewState) _then;

/// Create a copy of ViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? view = null,}) {
  return _then(ViewState(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ViewMode,view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as TaskView,
  ));
}
/// Create a copy of ViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskViewCopyWith<$Res> get view {
  
  return $TaskViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}


/// Adds pattern-matching-related methods to [ViewState].
extension ViewStatePatterns on ViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ViewState value)  $default,){
final _that = this;
switch (_that) {
case _ViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ViewState value)?  $default,){
final _that = this;
switch (_that) {
case _ViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ViewMode mode,  TaskView view)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ViewState() when $default != null:
return $default(_that.mode,_that.view);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ViewMode mode,  TaskView view)  $default,) {final _that = this;
switch (_that) {
case _ViewState():
return $default(_that.mode,_that.view);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ViewMode mode,  TaskView view)?  $default,) {final _that = this;
switch (_that) {
case _ViewState() when $default != null:
return $default(_that.mode,_that.view);case _:
  return null;

}
}

}

/// @nodoc


class _ViewState implements ViewState {
  const _ViewState({required this.mode, required this.view});
  

@override final  ViewMode mode;
@override final  TaskView view;

/// Create a copy of ViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ViewStateCopyWith<_ViewState> get copyWith => __$ViewStateCopyWithImpl<_ViewState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ViewState&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode {
    return Object.hash(runtimeType,mode,view);
}

@override
String toString() {
    return 'ViewState(mode: $mode, view: $view)';
}


}

/// @nodoc
abstract mixin class _$ViewStateCopyWith<$Res> implements $ViewStateCopyWith<$Res> {
  factory _$ViewStateCopyWith(_ViewState value, $Res Function(_ViewState) _then) = __$ViewStateCopyWithImpl;
@override @useResult
$Res call({
 ViewMode mode, TaskView view
});


@override $TaskViewCopyWith<$Res> get view;

}
/// @nodoc
class __$ViewStateCopyWithImpl<$Res>
    implements _$ViewStateCopyWith<$Res> {
  __$ViewStateCopyWithImpl(this._self, this._then);

  final _ViewState _self;
  final $Res Function(_ViewState) _then;

/// Create a copy of ViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? view = null,}) {
  return _then(_ViewState(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ViewMode,view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as TaskView,
  ));
}

/// Create a copy of ViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskViewCopyWith<$Res> get view {
  
  return $TaskViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

// dart format on
