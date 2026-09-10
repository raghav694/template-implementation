import 'package:app_template/features/auth/data/models/verify_otp_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads nested user and tokens from verify OTP JSON', () {
    final response = VerifyOtpResponse.fromJson({
      'user': {'id': 'u1', 'phone_number': '+910000000000', 'name': 'Raghav'},
      'tokens': {'access_token': 'access', 'refresh_token': 'refresh'},
    });

    expect(response.user.id, 'u1');
    expect(response.user.phone, '+910000000000');
    expect(response.user.displayName, 'Raghav');
    expect(response.tokens.accessToken, 'access');
    expect(response.tokens.refreshToken, 'refresh');
  });
}
