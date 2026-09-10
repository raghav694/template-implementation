// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PendingEvent {

 String get id; String get eventName; Map<String, dynamic> get payload; String? get state;
/// Create a copy of PendingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingEventCopyWith<PendingEvent> get copyWith => _$PendingEventCopyWithImpl<PendingEvent>(this as PendingEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,id,eventName,const DeepCollectionEquality().hash(payload),state);

@override
String toString() {
  return 'PendingEvent(id: $id, eventName: $eventName, payload: $payload, state: $state)';
}


}

/// @nodoc
abstract mixin class $PendingEventCopyWith<$Res>  {
  factory $PendingEventCopyWith(PendingEvent value, $Res Function(PendingEvent) _then) = _$PendingEventCopyWithImpl;
@useResult
$Res call({
 String id, String eventName, Map<String, dynamic> payload, String? state
});




}
/// @nodoc
class _$PendingEventCopyWithImpl<$Res>
    implements $PendingEventCopyWith<$Res> {
  _$PendingEventCopyWithImpl(this._self, this._then);

  final PendingEvent _self;
  final $Res Function(PendingEvent) _then;

/// Create a copy of PendingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventName = null,Object? payload = null,Object? state = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingEvent].
extension PendingEventPatterns on PendingEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingEvent value)  $default,){
final _that = this;
switch (_that) {
case _PendingEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingEvent value)?  $default,){
final _that = this;
switch (_that) {
case _PendingEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventName,  Map<String, dynamic> payload,  String? state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingEvent() when $default != null:
return $default(_that.id,_that.eventName,_that.payload,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventName,  Map<String, dynamic> payload,  String? state)  $default,) {final _that = this;
switch (_that) {
case _PendingEvent():
return $default(_that.id,_that.eventName,_that.payload,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventName,  Map<String, dynamic> payload,  String? state)?  $default,) {final _that = this;
switch (_that) {
case _PendingEvent() when $default != null:
return $default(_that.id,_that.eventName,_that.payload,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _PendingEvent implements PendingEvent {
  const _PendingEvent({required this.id, required this.eventName, final  Map<String, dynamic> payload = const {}, this.state}): _payload = payload;
  

@override final  String id;
@override final  String eventName;
 final  Map<String, dynamic> _payload;
@override@JsonKey() Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  String? state;

/// Create a copy of PendingEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingEventCopyWith<_PendingEvent> get copyWith => __$PendingEventCopyWithImpl<_PendingEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,id,eventName,const DeepCollectionEquality().hash(_payload),state);

@override
String toString() {
  return 'PendingEvent(id: $id, eventName: $eventName, payload: $payload, state: $state)';
}


}

/// @nodoc
abstract mixin class _$PendingEventCopyWith<$Res> implements $PendingEventCopyWith<$Res> {
  factory _$PendingEventCopyWith(_PendingEvent value, $Res Function(_PendingEvent) _then) = __$PendingEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventName, Map<String, dynamic> payload, String? state
});




}
/// @nodoc
class __$PendingEventCopyWithImpl<$Res>
    implements _$PendingEventCopyWith<$Res> {
  __$PendingEventCopyWithImpl(this._self, this._then);

  final _PendingEvent _self;
  final $Res Function(_PendingEvent) _then;

/// Create a copy of PendingEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventName = null,Object? payload = null,Object? state = freezed,}) {
  return _then(_PendingEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PendingEventsResponse {

 List<PendingEvent> get events;
/// Create a copy of PendingEventsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingEventsResponseCopyWith<PendingEventsResponse> get copyWith => _$PendingEventsResponseCopyWithImpl<PendingEventsResponse>(this as PendingEventsResponse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingEventsResponse&&const DeepCollectionEquality().equals(other.events, events));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(events));

@override
String toString() {
  return 'PendingEventsResponse(events: $events)';
}


}

/// @nodoc
abstract mixin class $PendingEventsResponseCopyWith<$Res>  {
  factory $PendingEventsResponseCopyWith(PendingEventsResponse value, $Res Function(PendingEventsResponse) _then) = _$PendingEventsResponseCopyWithImpl;
@useResult
$Res call({
 List<PendingEvent> events
});




}
/// @nodoc
class _$PendingEventsResponseCopyWithImpl<$Res>
    implements $PendingEventsResponseCopyWith<$Res> {
  _$PendingEventsResponseCopyWithImpl(this._self, this._then);

  final PendingEventsResponse _self;
  final $Res Function(PendingEventsResponse) _then;

/// Create a copy of PendingEventsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? events = null,}) {
  return _then(_self.copyWith(
events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<PendingEvent>,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingEventsResponse].
extension PendingEventsResponsePatterns on PendingEventsResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingEventsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingEventsResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingEventsResponse value)  $default,){
final _that = this;
switch (_that) {
case _PendingEventsResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingEventsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PendingEventsResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PendingEvent> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingEventsResponse() when $default != null:
return $default(_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PendingEvent> events)  $default,) {final _that = this;
switch (_that) {
case _PendingEventsResponse():
return $default(_that.events);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PendingEvent> events)?  $default,) {final _that = this;
switch (_that) {
case _PendingEventsResponse() when $default != null:
return $default(_that.events);case _:
  return null;

}
}

}

/// @nodoc


class _PendingEventsResponse implements PendingEventsResponse {
  const _PendingEventsResponse({final  List<PendingEvent> events = const []}): _events = events;
  

 final  List<PendingEvent> _events;
@override@JsonKey() List<PendingEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of PendingEventsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingEventsResponseCopyWith<_PendingEventsResponse> get copyWith => __$PendingEventsResponseCopyWithImpl<_PendingEventsResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingEventsResponse&&const DeepCollectionEquality().equals(other._events, _events));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_events));

@override
String toString() {
  return 'PendingEventsResponse(events: $events)';
}


}

/// @nodoc
abstract mixin class _$PendingEventsResponseCopyWith<$Res> implements $PendingEventsResponseCopyWith<$Res> {
  factory _$PendingEventsResponseCopyWith(_PendingEventsResponse value, $Res Function(_PendingEventsResponse) _then) = __$PendingEventsResponseCopyWithImpl;
@override @useResult
$Res call({
 List<PendingEvent> events
});




}
/// @nodoc
class __$PendingEventsResponseCopyWithImpl<$Res>
    implements _$PendingEventsResponseCopyWith<$Res> {
  __$PendingEventsResponseCopyWithImpl(this._self, this._then);

  final _PendingEventsResponse _self;
  final $Res Function(_PendingEventsResponse) _then;

/// Create a copy of PendingEventsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? events = null,}) {
  return _then(_PendingEventsResponse(
events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<PendingEvent>,
  ));
}


}

// dart format on
