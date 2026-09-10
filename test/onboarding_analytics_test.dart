import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/onboarding_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/recording_analytics_service.dart';

void main() {
  test(
    'onboardingCompleted fires once per install with number and loginType',
    () async {
      SharedPreferences.setMockInitialValues({});
      final analytics = RecordingAnalyticsService();

      await logOnboardingCompletedOnce(
        analytics: analytics,
        loginType: AnalyticsValues.loginTypeOtp,
        phoneNumber: '+919876543210',
      );
      await logOnboardingCompletedOnce(
        analytics: analytics,
        loginType: AnalyticsValues.loginTypeOtp,
        phoneNumber: '+919876543210',
      );

      expect(analytics.logged, hasLength(1));
      expect(analytics.logged.single.name, AnalyticsEvents.onboardingCompleted);
      expect(
        analytics.logged.single.parameters?[AnalyticsProperties.number],
        '919876543210',
      );
      expect(
        analytics.logged.single.parameters?[AnalyticsProperties.loginType],
        AnalyticsValues.loginTypeOtp,
      );
    },
  );
}
