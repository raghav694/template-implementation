import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/auth_event_properties.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fullNumber keeps country code and strips non-digits', () {
    expect(AuthEventProperties.fullNumber('+91 98765-43210'), '919876543210');
    expect(AuthEventProperties.fullNumber('9876543210'), '9876543210');
    expect(AuthEventProperties.fullNumber(null), '');
  });

  test('otp properties use full number and OTP loginType', () {
    final props = AuthEventProperties.otp(phoneNumber: '+919876543210');
    expect(props[AnalyticsProperties.number], '919876543210');
    expect(props[AnalyticsProperties.loginType], AnalyticsValues.loginTypeOtp);
  });

  test('omits number when the phone is empty', () {
    final props = AuthEventProperties.otp();
    expect(props.containsKey(AnalyticsProperties.number), isFalse);
    expect(props[AnalyticsProperties.loginType], AnalyticsValues.loginTypeOtp);
  });
}
