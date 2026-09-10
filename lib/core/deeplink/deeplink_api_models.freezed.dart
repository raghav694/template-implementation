// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deeplink_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResolveDeeplinkRequest {

 String? get link; String? get shortId;
/// Create a copy of ResolveDeeplinkRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolveDeeplinkRequestCopyWith<ResolveDeeplinkRequest> get copyWith => _$ResolveDeeplinkRequestCopyWithImpl<ResolveDeeplinkRequest>(this as ResolveDeeplinkRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolveDeeplinkRequest&&(identical(other.link, link) || other.link == link)&&(identical(other.shortId, shortId) || other.shortId == shortId));
}


@override
int get hashCode => Object.hash(runtimeType,link,shortId);

@override
String toString() {
  return 'ResolveDeeplinkRequest(link: $link, shortId: $shortId)';
}


}

/// @nodoc
abstract mixin class $ResolveDeeplinkRequestCopyWith<$Res>  {
  factory $ResolveDeeplinkRequestCopyWith(ResolveDeeplinkRequest value, $Res Function(ResolveDeeplinkRequest) _then) = _$ResolveDeeplinkRequestCopyWithImpl;
@useResult
$Res call({
 String? link, String? shortId
});




}
/// @nodoc
class _$ResolveDeeplinkRequestCopyWithImpl<$Res>
    implements $ResolveDeeplinkRequestCopyWith<$Res> {
  _$ResolveDeeplinkRequestCopyWithImpl(this._self, this._then);

  final ResolveDeeplinkRequest _self;
  final $Res Function(ResolveDeeplinkRequest) _then;

/// Create a copy of ResolveDeeplinkRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? link = freezed,Object? shortId = freezed,}) {
  return _then(_self.copyWith(
link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,shortId: freezed == shortId ? _self.shortId : shortId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ResolveDeeplinkRequest].
extension ResolveDeeplinkRequestPatterns on ResolveDeeplinkRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolveDeeplinkRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolveDeeplinkRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolveDeeplinkRequest value)  $default,){
final _that = this;
switch (_that) {
case _ResolveDeeplinkRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolveDeeplinkRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ResolveDeeplinkRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? link,  String? shortId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolveDeeplinkRequest() when $default != null:
return $default(_that.link,_that.shortId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? link,  String? shortId)  $default,) {final _that = this;
switch (_that) {
case _ResolveDeeplinkRequest():
return $default(_that.link,_that.shortId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? link,  String? shortId)?  $default,) {final _that = this;
switch (_that) {
case _ResolveDeeplinkRequest() when $default != null:
return $default(_that.link,_that.shortId);case _:
  return null;

}
}

}

/// @nodoc


class _ResolveDeeplinkRequest extends ResolveDeeplinkRequest {
  const _ResolveDeeplinkRequest({this.link, this.shortId}): super._();
  

@override final  String? link;
@override final  String? shortId;

/// Create a copy of ResolveDeeplinkRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolveDeeplinkRequestCopyWith<_ResolveDeeplinkRequest> get copyWith => __$ResolveDeeplinkRequestCopyWithImpl<_ResolveDeeplinkRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolveDeeplinkRequest&&(identical(other.link, link) || other.link == link)&&(identical(other.shortId, shortId) || other.shortId == shortId));
}


@override
int get hashCode => Object.hash(runtimeType,link,shortId);

@override
String toString() {
  return 'ResolveDeeplinkRequest(link: $link, shortId: $shortId)';
}


}

/// @nodoc
abstract mixin class _$ResolveDeeplinkRequestCopyWith<$Res> implements $ResolveDeeplinkRequestCopyWith<$Res> {
  factory _$ResolveDeeplinkRequestCopyWith(_ResolveDeeplinkRequest value, $Res Function(_ResolveDeeplinkRequest) _then) = __$ResolveDeeplinkRequestCopyWithImpl;
@override @useResult
$Res call({
 String? link, String? shortId
});




}
/// @nodoc
class __$ResolveDeeplinkRequestCopyWithImpl<$Res>
    implements _$ResolveDeeplinkRequestCopyWith<$Res> {
  __$ResolveDeeplinkRequestCopyWithImpl(this._self, this._then);

  final _ResolveDeeplinkRequest _self;
  final $Res Function(_ResolveDeeplinkRequest) _then;

/// Create a copy of ResolveDeeplinkRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? link = freezed,Object? shortId = freezed,}) {
  return _then(_ResolveDeeplinkRequest(
link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,shortId: freezed == shortId ? _self.shortId : shortId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ResolveDeeplinkResponse {

 String? get originalUrl;
/// Create a copy of ResolveDeeplinkResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolveDeeplinkResponseCopyWith<ResolveDeeplinkResponse> get copyWith => _$ResolveDeeplinkResponseCopyWithImpl<ResolveDeeplinkResponse>(this as ResolveDeeplinkResponse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolveDeeplinkResponse&&(identical(other.originalUrl, originalUrl) || other.originalUrl == originalUrl));
}


@override
int get hashCode => Object.hash(runtimeType,originalUrl);

@override
String toString() {
  return 'ResolveDeeplinkResponse(originalUrl: $originalUrl)';
}


}

/// @nodoc
abstract mixin class $ResolveDeeplinkResponseCopyWith<$Res>  {
  factory $ResolveDeeplinkResponseCopyWith(ResolveDeeplinkResponse value, $Res Function(ResolveDeeplinkResponse) _then) = _$ResolveDeeplinkResponseCopyWithImpl;
@useResult
$Res call({
 String? originalUrl
});




}
/// @nodoc
class _$ResolveDeeplinkResponseCopyWithImpl<$Res>
    implements $ResolveDeeplinkResponseCopyWith<$Res> {
  _$ResolveDeeplinkResponseCopyWithImpl(this._self, this._then);

  final ResolveDeeplinkResponse _self;
  final $Res Function(ResolveDeeplinkResponse) _then;

/// Create a copy of ResolveDeeplinkResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originalUrl = freezed,}) {
  return _then(_self.copyWith(
originalUrl: freezed == originalUrl ? _self.originalUrl : originalUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ResolveDeeplinkResponse].
extension ResolveDeeplinkResponsePatterns on ResolveDeeplinkResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolveDeeplinkResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolveDeeplinkResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolveDeeplinkResponse value)  $default,){
final _that = this;
switch (_that) {
case _ResolveDeeplinkResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolveDeeplinkResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ResolveDeeplinkResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? originalUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolveDeeplinkResponse() when $default != null:
return $default(_that.originalUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? originalUrl)  $default,) {final _that = this;
switch (_that) {
case _ResolveDeeplinkResponse():
return $default(_that.originalUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? originalUrl)?  $default,) {final _that = this;
switch (_that) {
case _ResolveDeeplinkResponse() when $default != null:
return $default(_that.originalUrl);case _:
  return null;

}
}

}

/// @nodoc


class _ResolveDeeplinkResponse extends ResolveDeeplinkResponse {
  const _ResolveDeeplinkResponse({this.originalUrl}): super._();
  

@override final  String? originalUrl;

/// Create a copy of ResolveDeeplinkResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolveDeeplinkResponseCopyWith<_ResolveDeeplinkResponse> get copyWith => __$ResolveDeeplinkResponseCopyWithImpl<_ResolveDeeplinkResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolveDeeplinkResponse&&(identical(other.originalUrl, originalUrl) || other.originalUrl == originalUrl));
}


@override
int get hashCode => Object.hash(runtimeType,originalUrl);

@override
String toString() {
  return 'ResolveDeeplinkResponse(originalUrl: $originalUrl)';
}


}

/// @nodoc
abstract mixin class _$ResolveDeeplinkResponseCopyWith<$Res> implements $ResolveDeeplinkResponseCopyWith<$Res> {
  factory _$ResolveDeeplinkResponseCopyWith(_ResolveDeeplinkResponse value, $Res Function(_ResolveDeeplinkResponse) _then) = __$ResolveDeeplinkResponseCopyWithImpl;
@override @useResult
$Res call({
 String? originalUrl
});




}
/// @nodoc
class __$ResolveDeeplinkResponseCopyWithImpl<$Res>
    implements _$ResolveDeeplinkResponseCopyWith<$Res> {
  __$ResolveDeeplinkResponseCopyWithImpl(this._self, this._then);

  final _ResolveDeeplinkResponse _self;
  final $Res Function(_ResolveDeeplinkResponse) _then;

/// Create a copy of ResolveDeeplinkResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalUrl = freezed,}) {
  return _then(_ResolveDeeplinkResponse(
originalUrl: freezed == originalUrl ? _self.originalUrl : originalUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
