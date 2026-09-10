import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_api_models.freezed.dart';
part 'auth_api_models.g.dart';

@freezed
abstract class SendOtpRequest with _$SendOtpRequest {
  const factory SendOtpRequest({
    @JsonKey(name: 'phone_no') required String phone,
  }) = _SendOtpRequest;

  factory SendOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$SendOtpRequestFromJson(json);
}

@freezed
abstract class VerifyOtpRequest with _$VerifyOtpRequest {
  const factory VerifyOtpRequest({
    @JsonKey(name: 'phone_no') required String phone,
    required String otp,
  }) = _VerifyOtpRequest;

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpRequestFromJson(json);
}

class VerifyTruecallerRequest {
  const VerifyTruecallerRequest({
    required this.authorizationCode,
    required this.codeVerifier,
  });

  final String authorizationCode;
  final String codeVerifier;

  Map<String, dynamic> toJson() => {
    'authorization_code': authorizationCode,
    'code_verifier': codeVerifier,
  };
}

class RefreshTokenRequest {
  const RefreshTokenRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}

@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    @Default('') String accessToken,
    @Default('') String refreshToken,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }
}
