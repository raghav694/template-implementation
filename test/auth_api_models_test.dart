import 'package:app_template/core/network/api_routes.dart';
import 'package:app_template/features/auth/data/models/auth_api_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('send OTP body uses phone_no and omits tenant', () {
    final json = const SendOtpRequest(phone: '919876543210').toJson();

    expect(json, {'phone_no': '919876543210'});
  });

  test('verify OTP body uses phone_no and otp', () {
    final json = const VerifyOtpRequest(
      phone: '919876543210',
      otp: '123456',
    ).toJson();

    expect(json, {'phone_no': '919876543210', 'otp': '123456'});
  });

  test('refresh token body uses refresh_token', () {
    final json = const RefreshTokenRequest(refreshToken: 'rt-1').toJson();

    expect(json, {'refresh_token': 'rt-1'});
  });

  test('truecaller body has no tenant_code', () {
    final json = const VerifyTruecallerRequest(
      authorizationCode: 'code',
      codeVerifier: 'verifier',
    ).toJson();

    expect(json.containsKey('tenant_code'), isFalse);
    expect(json['authorization_code'], 'code');
    expect(json['code_verifier'], 'verifier');
  });

  test('refresh path includes tenant', () {
    expect(
      ApiRoutes.refreshTokenFor('auth-tenant-1'),
      '/public/tenants/auth-tenant-1/token/refresh',
    );
    expect(
      ApiRoutes.isUnauthenticatedAuthPath(
        '/public/tenants/auth-tenant-1/otp/send',
      ),
      isTrue,
    );
    expect(
      ApiRoutes.isUnauthenticatedAuthPath(
        '/public/tenants/auth-tenant-1/truecaller/verify',
      ),
      isTrue,
    );
  });
}
