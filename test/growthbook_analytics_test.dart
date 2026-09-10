import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/growthbook/growthbook_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_growthbook_service.dart';
import 'fakes/recording_analytics_service.dart';

void main() {
  test('skips the snapshot when no features are on', () async {
    final analytics = RecordingAnalyticsService();

    await trackEnabledGrowthBookFeatures(
      analytics,
      FakeGrowthBookService(),
      isInit: true,
    );

    expect(analytics.logged, isEmpty);
  });

  test('logs enabled features with isInit', () async {
    final analytics = RecordingAnalyticsService();

    await trackEnabledGrowthBookFeatures(
      analytics,
      FakeGrowthBookService(
        enabled: {'forceUpdate': true, 'paywall_plan_variant': 'yearly'},
      ),
      isInit: true,
    );

    expect(analytics.logged, hasLength(1));
    expect(
      analytics.logged.single.name,
      AnalyticsEvents.enabledGrowthBookFeatures,
    );
    final params = analytics.logged.single.parameters!;
    expect(params[AnalyticsProperties.isInit], true);
    expect(params['forceUpdate'], true);
    expect(params['paywall_plan_variant'], 'yearly');
  });
}
