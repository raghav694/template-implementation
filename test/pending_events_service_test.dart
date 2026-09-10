import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/features/analytics/data/pending_event.dart';
import 'package:app_template/features/analytics/data/pending_events_datasource_impl.dart';
import 'package:app_template/features/analytics/pending_events_service.dart';
import 'package:app_template/features/analytics/pending_purchase_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_pending_events_datasource.dart';
import 'fakes/recording_analytics_service.dart';

void main() {
  test('parses a wrapped events list and skips empty rows', () {
    final events = PendingEventsDataSourceImpl.parseList({
      'events': [
        {
          'id': 'evt_1',
          'event_name': 'addBalanceSuccess',
          'payload': {'plan_id': 'monthly'},
          'state': 'pending',
        },
        {'id': '', 'event_name': 'addBalanceSuccess'},
        {'id': 'evt_2', 'event_name': ''},
      ],
    });

    expect(events, hasLength(1));
    expect(events.single.id, 'evt_1');
    expect(events.single.payload['plan_id'], 'monthly');
  });

  test('converts paise amounts to rupees and prefers trial amount', () {
    expect(PendingEventsService.rupeesFrom({'amount': 14900}), 149);
    expect(
      PendingEventsService.rupeesFrom({
        'plan_trial_amount': 1,
        'amount': 14900,
      }),
      1,
    );
  });

  test('tracks addBalanceSuccess then marks the row done', () async {
    const event = PendingEvent(
      id: 'evt_1',
      eventName: 'addBalanceSuccess',
      payload: {
        'subscription_id': 'sub_1',
        'payment_order_id': 'order_1',
        'plan_id': 'monthly',
        'amount': 9900,
        'plan_trial_amount': 1,
        'plan_amount': 14900,
        'media_url': 'https://cdn.example/hero.mp4',
        'plan_frequency': 'month',
      },
    );
    final source = FakePendingEventsDataSource(events: const [event]);
    final analytics = RecordingAnalyticsService();
    final service = PendingEventsService(source, analytics);

    await service.processPendingEvents();

    expect(analytics.logged, hasLength(1));
    expect(analytics.logged.single.name, AnalyticsEvents.addBalanceSuccess);
    final params = analytics.logged.single.parameters!;
    expect(params[AnalyticsProperties.eventId], 'evt_1');
    expect(params[AnalyticsProperties.subscriptionId], 'sub_1');
    expect(params[AnalyticsProperties.paymentId], 'order_1');
    expect(params[AnalyticsProperties.planId], 'monthly');
    expect(params[AnalyticsProperties.planPrice], 1.0);
    expect(params[AnalyticsProperties.amount], 1.0);
    expect(params[AnalyticsProperties.trialAmount], 1);
    expect(params[AnalyticsProperties.subscriptionAmount], 149.0);
    expect(
      params[AnalyticsProperties.mediaURL],
      'https://cdn.example/hero.mp4',
    );
    expect(params[AnalyticsProperties.planFrequency], 'month');
    expect(
      params[AnalyticsProperties.subscriptionStatus],
      AnalyticsValues.free,
    );
    expect(params[AnalyticsProperties.platform], isNotEmpty);
    expect(source.markedDone, ['evt_1']);
  });

  test('does not mark done when tracking fails', () async {
    const event = PendingEvent(id: 'evt_1', eventName: 'addBalanceSuccess');
    final source = FakePendingEventsDataSource(events: const [event]);
    final analytics = RecordingAnalyticsService()
      ..throwOnLog = Exception('down');
    final service = PendingEventsService(source, analytics);

    await service.processPendingEvents();

    expect(source.markedDone, isEmpty);
  });

  test('maps subscription renewal names onto client event constants', () {
    expect(
      PendingEventsService.wireName('subscriptionRenewed'),
      AnalyticsEvents.subscriptionCharged,
    );
    expect(
      PendingEventsService.wireName('subscriptionRenewedFailed'),
      AnalyticsEvents.subscriptionChargeFailed,
    );
    expect(
      PendingEventsService.wireName('subscriptionRenewalFailed'),
      AnalyticsEvents.subscriptionChargeFailed,
    );
    expect(
      AnalyticsEvents.subscriptionChargeFailed,
      'subscriptionRenewalFailed',
    );
  });

  test('maps subscriptionCount from the drain payload', () {
    const event = PendingEvent(
      id: 'evt_1',
      eventName: 'subscriptionRenewed',
      payload: {
        'subscription_id': 'sub_1',
        'plan_trial_amount': 1,
        'plan_amount': 14900,
        'plan_frequency': 'month',
        'paid_count': 3,
        'subscription_renewal_notification_count': 2,
        'reason': 'mandate_failed',
      },
    );
    final params = PendingEventsService.properties(event);
    expect(params[AnalyticsProperties.subscriptionCount], 3);
    expect(params[AnalyticsProperties.subscriptionRenewalNotificationCount], 2);
    expect(params[AnalyticsProperties.reason], 'mandate_failed');
    expect(params[AnalyticsProperties.planFrequency], 'month');
  });

  test(
    'marks addBalanceSuccess done when the client already reported it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = PendingPurchaseCache(prefs: prefs);
      await cache.markReported('sub_1');
      const event = PendingEvent(
        id: 'evt_1',
        eventName: 'addBalanceSuccess',
        payload: {'subscription_id': 'sub_1'},
      );
      final source = FakePendingEventsDataSource(events: const [event]);
      final analytics = RecordingAnalyticsService();
      final service = PendingEventsService(source, analytics, cache: cache);

      await service.processPendingEvents();

      expect(analytics.logged, isEmpty);
      expect(source.markedDone, ['evt_1']);
    },
  );

  test('swallows a list failure so checkout is not blocked', () async {
    final source = FakePendingEventsDataSource(listError: Exception('offline'));
    final analytics = RecordingAnalyticsService();
    final service = PendingEventsService(source, analytics);

    await service.processPendingEvents();

    expect(analytics.logged, isEmpty);
    expect(source.markedDone, isEmpty);
  });
}
