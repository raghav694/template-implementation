import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/features/analytics/pending_purchase_cache.dart';
import 'package:app_template/features/analytics/purchase_success_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/recording_analytics_service.dart';

void main() {
  late SharedPreferences prefs;
  late PendingPurchaseCache cache;
  late RecordingAnalyticsService analytics;
  late PurchaseSuccessReporter reporter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cache = PendingPurchaseCache(prefs: prefs);
    analytics = RecordingAnalyticsService();
    reporter = PurchaseSuccessReporter(cache, analytics);
  });

  test(
    'flushOnStreamSuccess sends firstAddBalanceSuccess then addBalanceSuccess',
    () async {
      await reporter.markInitiated(
        userId: 'user_1',
        planId: 'monthly',
        subscriptionStatus: AnalyticsValues.free,
        amountInr: 99,
        trialAmount: 1,
        subscriptionAmount: 149,
        mediaURL: 'https://cdn.example/hero.mp4',
        planFrequency: 'month',
        paymentApps: const ['GPay'],
        paymentMethod: AnalyticsValues.paymentMethodQrCode,
      );
      await reporter.flushOnStreamSuccess(
        userId: 'user_1',
        subscriptionId: 'sub_1',
        paymentId: 'pay_1',
        planId: 'monthly',
        amountInr: 99,
      );

      expect(analytics.logged, hasLength(2));
      expect(analytics.logged.map((e) => e.name).toList(), [
        AnalyticsEvents.firstAddBalanceSuccess,
        AnalyticsEvents.addBalanceSuccess,
      ]);
      expect(
        analytics.logged.last.parameters?[AnalyticsProperties.paymentId],
        'pay_1',
      );
      expect(
        analytics.logged.last.parameters?[AnalyticsProperties.subscriptionId],
        'sub_1',
      );
      expect(
        analytics.logged.last.parameters?[AnalyticsProperties.trialAmount],
        1,
      );
      expect(
        analytics.logged.last.parameters?[AnalyticsProperties
            .subscriptionAmount],
        149,
      );
      expect(
        analytics.logged.last.parameters?[AnalyticsProperties.mediaURL],
        'https://cdn.example/hero.mp4',
      );
      expect(
        analytics.logged.last.parameters?[AnalyticsProperties.paymentMethod],
        AnalyticsValues.paymentMethodQrCode,
      );
      expect(
        analytics.logged.last.parameters?[AnalyticsProperties.paymentApps],
        ['GPay'],
      );

      await reporter.flushOnStreamSuccess(
        userId: 'user_1',
        subscriptionId: 'sub_1',
        paymentId: 'pay_1',
      );
      expect(analytics.logged, hasLength(2));
    },
  );

  test('renewal checkout skips firstAddBalanceSuccess', () async {
    await reporter.markInitiated(
      userId: 'user_1',
      planId: 'monthly',
      subscriptionStatus: AnalyticsValues.premium,
    );
    await reporter.flushOnStreamSuccess(
      userId: 'user_1',
      subscriptionId: 'sub_1',
      paymentId: 'pay_1',
    );

    expect(analytics.logged, hasLength(1));
    expect(analytics.logged.single.name, AnalyticsEvents.addBalanceSuccess);
  });

  test(
    'flushOnPremiumResume sends only after initiate for that user',
    () async {
      await reporter.markInitiated(
        userId: 'user_1',
        planId: 'monthly',
        subscriptionStatus: AnalyticsValues.free,
      );
      await reporter.attachCheckout(
        subscriptionId: 'sub_1',
        paymentId: 'pay_1',
      );

      await reporter.flushOnPremiumResume(userId: 'other');
      expect(analytics.logged, isEmpty);

      await reporter.flushOnPremiumResume(userId: 'user_1');
      expect(analytics.logged, hasLength(2));
      expect(analytics.logged.map((e) => e.name).toList(), [
        AnalyticsEvents.firstAddBalanceSuccess,
        AnalyticsEvents.addBalanceSuccess,
      ]);
    },
  );
}
