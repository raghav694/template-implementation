// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SendOtpRequest _$SendOtpRequestFromJson(Map<String, dynamic> json) =>
    _SendOtpRequest(phone: json['phone_no'] as String);

Map<String, dynamic> _$SendOtpRequestToJson(_SendOtpRequest instance) =>
    <String, dynamic>{'phone_no': instance.phone};

_VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) =>
    _VerifyOtpRequest(
      phone: json['phone_no'] as String,
      otp: json['otp'] as String,
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(_VerifyOtpRequest instance) =>
    <String, dynamic>{'phone_no': instance.phone, 'otp': instance.otp};
