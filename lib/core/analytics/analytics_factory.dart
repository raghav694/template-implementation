import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/analytics/implementations/facebook_analytics_service.dart';
import 'package:app_template/core/analytics/implementations/firebase_analytics_service.dart';
import 'package:app_template/core/analytics/implementations/mixpanel_analytics_service.dart';
import 'package:app_template/core/analytics/multi_analytics_service.dart';

/// Single registration point for analytics providers.
///
/// Switch providers by editing this list — feature code never changes.
/// Mixpanel no-ops when `MIXPANEL_TOKEN` is empty.
/// Facebook maps onboardingCompleted, paymentScreen, addBalanceInitiated,
/// firstAddBalanceSuccess, and addBalanceSuccess to standard Meta events.
/// `subscriptionRenewed` → Subscribe only via the backend pending drain.
AnalyticsService createAnalyticsService() {
  return MultiAnalyticsService([
    FirebaseAnalyticsService(),
    MixpanelAnalyticsService(),
    FacebookAnalyticsService(),
  ]);
}
