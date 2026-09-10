import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_template/core/network/json_map.dart';
import 'package:app_template/features/auth/data/models/auth_api_models.dart';
import 'package:app_template/features/auth/data/models/user_model.dart';

part 'verify_otp_response.freezed.dart';

@freezed
abstract class VerifyOtpResponse with _$VerifyOtpResponse {
  const VerifyOtpResponse._();

  const factory VerifyOtpResponse({
    required UserModel user,
    @Default(AuthTokens()) AuthTokens tokens,
  }) = _VerifyOtpResponse;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    final map = JsonMap.of(json);
    final userMap = JsonMap.of(map['user']);
    final tokensMap = JsonMap.of(map['tokens']);
    return VerifyOtpResponse(
      user: UserModel.fromJson(userMap.isNotEmpty ? userMap : map),
      tokens: AuthTokens.fromJson(tokensMap.isNotEmpty ? tokensMap : map),
    );
  }
}
