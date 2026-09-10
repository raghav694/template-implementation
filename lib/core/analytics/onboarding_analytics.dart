import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/analytics/auth_event_properties.dart';

/// Fires [AnalyticsEvents.onboardingCompleted] once per install after the
/// user's first successful login.
Future<void> logOnboardingCompletedOnce({
  required AnalyticsService analytics,
  required String loginType,
  String? phoneNumber,
}) async {
  final prefs = await SharedPreferences.getInstance();
  const key = 'analytics_onboarding_completed_logged';
  if (prefs.getBool(key) ?? false) return;

  await analytics.logEvent(
    AnalyticsEvents.onboardingCompleted,
    parameters: AuthEventProperties.forLoginType(
      loginType: loginType,
      phoneNumber: phoneNumber,
    ),
  );

  await prefs.setBool(key, true);
}
