// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlanDto {

 String get id; String get label; int get priceAmount; String get billingCycle; PlanCategory get category; String get currencyCode; int? get originalPriceAmount; int get trialDays; int? get trialAmount; String? get videoUrl;
/// Create a copy of PlanDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanDtoCopyWith<PlanDto> get copyWith => _$PlanDtoCopyWithImpl<PlanDto>(this as PlanDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.priceAmount, priceAmount) || other.priceAmount == priceAmount)&&(identical(other.billingCycle, billingCycle) || other.billingCycle == billingCycle)&&(identical(other.category, category) || other.category == category)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.originalPriceAmount, originalPriceAmount) || other.originalPriceAmount == originalPriceAmount)&&(identical(other.trialDays, trialDays) || other.trialDays == trialDays)&&(identical(other.trialAmount, trialAmount) || other.trialAmount == trialAmount)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,priceAmount,billingCycle,category,currencyCode,originalPriceAmount,trialDays,trialAmount,videoUrl);

@override
String toString() {
  return 'PlanDto(id: $id, label: $label, priceAmount: $priceAmount, billingCycle: $billingCycle, category: $category, currencyCode: $currencyCode, originalPriceAmount: $originalPriceAmount, trialDays: $trialDays, trialAmount: $trialAmount, videoUrl: $videoUrl)';
}


}

/// @nodoc
abstract mixin class $PlanDtoCopyWith<$Res>  {
  factory $PlanDtoCopyWith(PlanDto value, $Res Function(PlanDto) _then) = _$PlanDtoCopyWithImpl;
@useResult
$Res call({
 String id, String label, int priceAmount, String billingCycle, PlanCategory category, String currencyCode, int? originalPriceAmount, int trialDays, int? trialAmount, String? videoUrl
});




}
/// @nodoc
class _$PlanDtoCopyWithImpl<$Res>
    implements $PlanDtoCopyWith<$Res> {
  _$PlanDtoCopyWithImpl(this._self, this._then);

  final PlanDto _self;
  final $Res Function(PlanDto) _then;

/// Create a copy of PlanDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? priceAmount = null,Object? billingCycle = null,Object? category = null,Object? currencyCode = null,Object? originalPriceAmount = freezed,Object? trialDays = null,Object? trialAmount = freezed,Object? videoUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,priceAmount: null == priceAmount ? _self.priceAmount : priceAmount // ignore: cast_nullable_to_non_nullable
as int,billingCycle: null == billingCycle ? _self.billingCycle : billingCycle // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as PlanCategory,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,originalPriceAmount: freezed == originalPriceAmount ? _self.originalPriceAmount : originalPriceAmount // ignore: cast_nullable_to_non_nullable
as int?,trialDays: null == trialDays ? _self.trialDays : trialDays // ignore: cast_nullable_to_non_nullable
as int,trialAmount: freezed == trialAmount ? _self.trialAmount : trialAmount // ignore: cast_nullable_to_non_nullable
as int?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanDto].
extension PlanDtoPatterns on PlanDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanDto value)  $default,){
final _that = this;
switch (_that) {
case _PlanDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanDto value)?  $default,){
final _that = this;
switch (_that) {
case _PlanDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  int priceAmount,  String billingCycle,  PlanCategory category,  String currencyCode,  int? originalPriceAmount,  int trialDays,  int? trialAmount,  String? videoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanDto() when $default != null:
return $default(_that.id,_that.label,_that.priceAmount,_that.billingCycle,_that.category,_that.currencyCode,_that.originalPriceAmount,_that.trialDays,_that.trialAmount,_that.videoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  int priceAmount,  String billingCycle,  PlanCategory category,  String currencyCode,  int? originalPriceAmount,  int trialDays,  int? trialAmount,  String? videoUrl)  $default,) {final _that = this;
switch (_that) {
case _PlanDto():
return $default(_that.id,_that.label,_that.priceAmount,_that.billingCycle,_that.category,_that.currencyCode,_that.originalPriceAmount,_that.trialDays,_that.trialAmount,_that.videoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  int priceAmount,  String billingCycle,  PlanCategory category,  String currencyCode,  int? originalPriceAmount,  int trialDays,  int? trialAmount,  String? videoUrl)?  $default,) {final _that = this;
switch (_that) {
case _PlanDto() when $default != null:
return $default(_that.id,_that.label,_that.priceAmount,_that.billingCycle,_that.category,_that.currencyCode,_that.originalPriceAmount,_that.trialDays,_that.trialAmount,_that.videoUrl);case _:
  return null;

}
}

}

/// @nodoc


class _PlanDto extends PlanDto {
  const _PlanDto({required this.id, required this.label, required this.priceAmount, required this.billingCycle, this.category = PlanCategory.recurring, this.currencyCode = 'INR', this.originalPriceAmount, this.trialDays = 0, this.trialAmount, this.videoUrl}): super._();
  

@override final  String id;
@override final  String label;
@override final  int priceAmount;
@override final  String billingCycle;
@override@JsonKey() final  PlanCategory category;
@override@JsonKey() final  String currencyCode;
@override final  int? originalPriceAmount;
@override@JsonKey() final  int trialDays;
@override final  int? trialAmount;
@override final  String? videoUrl;

/// Create a copy of PlanDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanDtoCopyWith<_PlanDto> get copyWith => __$PlanDtoCopyWithImpl<_PlanDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanDto&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.priceAmount, priceAmount) || other.priceAmount == priceAmount)&&(identical(other.billingCycle, billingCycle) || other.billingCycle == billingCycle)&&(identical(other.category, category) || other.category == category)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.originalPriceAmount, originalPriceAmount) || other.originalPriceAmount == originalPriceAmount)&&(identical(other.trialDays, trialDays) || other.trialDays == trialDays)&&(identical(other.trialAmount, trialAmount) || other.trialAmount == trialAmount)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,priceAmount,billingCycle,category,currencyCode,originalPriceAmount,trialDays,trialAmount,videoUrl);

@override
String toString() {
  return 'PlanDto(id: $id, label: $label, priceAmount: $priceAmount, billingCycle: $billingCycle, category: $category, currencyCode: $currencyCode, originalPriceAmount: $originalPriceAmount, trialDays: $trialDays, trialAmount: $trialAmount, videoUrl: $videoUrl)';
}


}

/// @nodoc
abstract mixin class _$PlanDtoCopyWith<$Res> implements $PlanDtoCopyWith<$Res> {
  factory _$PlanDtoCopyWith(_PlanDto value, $Res Function(_PlanDto) _then) = __$PlanDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, int priceAmount, String billingCycle, PlanCategory category, String currencyCode, int? originalPriceAmount, int trialDays, int? trialAmount, String? videoUrl
});




}
/// @nodoc
class __$PlanDtoCopyWithImpl<$Res>
    implements _$PlanDtoCopyWith<$Res> {
  __$PlanDtoCopyWithImpl(this._self, this._then);

  final _PlanDto _self;
  final $Res Function(_PlanDto) _then;

/// Create a copy of PlanDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? priceAmount = null,Object? billingCycle = null,Object? category = null,Object? currencyCode = null,Object? originalPriceAmount = freezed,Object? trialDays = null,Object? trialAmount = freezed,Object? videoUrl = freezed,}) {
  return _then(_PlanDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,priceAmount: null == priceAmount ? _self.priceAmount : priceAmount // ignore: cast_nullable_to_non_nullable
as int,billingCycle: null == billingCycle ? _self.billingCycle : billingCycle // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as PlanCategory,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,originalPriceAmount: freezed == originalPriceAmount ? _self.originalPriceAmount : originalPriceAmount // ignore: cast_nullable_to_non_nullable
as int?,trialDays: null == trialDays ? _self.trialDays : trialDays // ignore: cast_nullable_to_non_nullable
as int,trialAmount: freezed == trialAmount ? _self.trialAmount : trialAmount // ignore: cast_nullable_to_non_nullable
as int?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PlansResponse {

 List<PlanDto> get plans;
/// Create a copy of PlansResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlansResponseCopyWith<PlansResponse> get copyWith => _$PlansResponseCopyWithImpl<PlansResponse>(this as PlansResponse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlansResponse&&const DeepCollectionEquality().equals(other.plans, plans));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(plans));

@override
String toString() {
  return 'PlansResponse(plans: $plans)';
}


}

/// @nodoc
abstract mixin class $PlansResponseCopyWith<$Res>  {
  factory $PlansResponseCopyWith(PlansResponse value, $Res Function(PlansResponse) _then) = _$PlansResponseCopyWithImpl;
@useResult
$Res call({
 List<PlanDto> plans
});




}
/// @nodoc
class _$PlansResponseCopyWithImpl<$Res>
    implements $PlansResponseCopyWith<$Res> {
  _$PlansResponseCopyWithImpl(this._self, this._then);

  final PlansResponse _self;
  final $Res Function(PlansResponse) _then;

/// Create a copy of PlansResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plans = null,}) {
  return _then(_self.copyWith(
plans: null == plans ? _self.plans : plans // ignore: cast_nullable_to_non_nullable
as List<PlanDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlansResponse].
extension PlansResponsePatterns on PlansResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlansResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlansResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlansResponse value)  $default,){
final _that = this;
switch (_that) {
case _PlansResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlansResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PlansResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PlanDto> plans)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlansResponse() when $default != null:
return $default(_that.plans);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PlanDto> plans)  $default,) {final _that = this;
switch (_that) {
case _PlansResponse():
return $default(_that.plans);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PlanDto> plans)?  $default,) {final _that = this;
switch (_that) {
case _PlansResponse() when $default != null:
return $default(_that.plans);case _:
  return null;

}
}

}

/// @nodoc


class _PlansResponse implements PlansResponse {
  const _PlansResponse({final  List<PlanDto> plans = const []}): _plans = plans;
  

 final  List<PlanDto> _plans;
@override@JsonKey() List<PlanDto> get plans {
  if (_plans is EqualUnmodifiableListView) return _plans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plans);
}


/// Create a copy of PlansResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlansResponseCopyWith<_PlansResponse> get copyWith => __$PlansResponseCopyWithImpl<_PlansResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlansResponse&&const DeepCollectionEquality().equals(other._plans, _plans));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_plans));

@override
String toString() {
  return 'PlansResponse(plans: $plans)';
}


}

/// @nodoc
abstract mixin class _$PlansResponseCopyWith<$Res> implements $PlansResponseCopyWith<$Res> {
  factory _$PlansResponseCopyWith(_PlansResponse value, $Res Function(_PlansResponse) _then) = __$PlansResponseCopyWithImpl;
@override @useResult
$Res call({
 List<PlanDto> plans
});




}
/// @nodoc
class __$PlansResponseCopyWithImpl<$Res>
    implements _$PlansResponseCopyWith<$Res> {
  __$PlansResponseCopyWithImpl(this._self, this._then);

  final _PlansResponse _self;
  final $Res Function(_PlansResponse) _then;

/// Create a copy of PlansResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plans = null,}) {
  return _then(_PlansResponse(
plans: null == plans ? _self._plans : plans // ignore: cast_nullable_to_non_nullable
as List<PlanDto>,
  ));
}


}

// dart format on
