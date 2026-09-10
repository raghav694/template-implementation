import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/growthbook/growthbook_service.dart';

/// Snapshot of enabled GrowthBook features, fired at login with `isInit: true`.
Future<void> trackEnabledGrowthBookFeatures(
  AnalyticsService analytics,
  GrowthBookService growthBook, {
  required bool isInit,
}) async {
  final enabled = growthBook.enabledFeatures();
  if (enabled.isEmpty) return;

  await analytics.logEvent(
    AnalyticsEvents.enabledGrowthBookFeatures,
    parameters: {...enabled, AnalyticsProperties.isInit: isInit},
  );
}
