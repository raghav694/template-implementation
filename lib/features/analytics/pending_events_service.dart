import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/features/analytics/data/pending_event.dart';
import 'package:app_template/features/analytics/data/pending_events_datasource.dart';
import 'package:app_template/features/analytics/pending_purchase_cache.dart';

/// Fetches backend-queued analytics rows, tracks them locally (Mixpanel,
/// Firebase, Meta), then marks each row done.
///
/// Renewal events (`subscriptionRenewed`, `subscriptionRenewalFailed`,
/// `subscriptionRenewalNotified`) are produced by the backend (charge /
/// webhook). This drain is the only client path — checkout must not log them.
///
/// Safe to call often — failures are swallowed so checkout/home never
/// depend on analytics. Mark-done runs only after a successful track so a
/// failed send is retried on the next drain.
///
/// Client [PurchaseSuccessReporter] can send `addBalanceSuccess` first.
/// This drain skips (and marks done) rows whose `subscription_id` was
/// already reported so Meta Purchase is not double-counted.
class PendingEventsService {
  PendingEventsService(this._dataSource, this._analytics, {this.cache});

  final PendingEventsDataSource _dataSource;
  final AnalyticsService _analytics;
  final PendingPurchaseCache? cache;

  Future<void> processPendingEvents() async {
    final List<PendingEvent> events;
    try {
      events = await _dataSource.listPending();
    } catch (error, stackTrace) {
      debugPrint('PendingEventsService: list failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    for (final event in events) {
      await _process(event);
    }
  }

  /// Call after a successful checkout so a just-queued `addBalanceSuccess`
  /// is drained without waiting for the next resume.
  Future<void> onPaymentSucceeded() => processPendingEvents();

  Future<void> _process(PendingEvent event) async {
    final subscriptionId = event.payload['subscription_id']?.toString();
    if (event.eventName == 'addBalanceSuccess' &&
        await cache?.hasReported(subscriptionId) == true) {
      try {
        await _dataSource.markDone(event.id);
      } catch (_) {}
      return;
    }

    try {
      await _analytics.logEvent(
        wireName(event.eventName),
        parameters: properties(event),
      );
    } catch (error, stackTrace) {
      debugPrint('PendingEventsService: track ${event.id} failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    try {
      await _dataSource.markDone(event.id);
    } catch (error, stackTrace) {
      debugPrint('PendingEventsService: markDone ${event.id} failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @visibleForTesting
  static String wireName(String serverName) {
    return switch (serverName) {
      'addBalanceSuccess' => AnalyticsEvents.addBalanceSuccess,
      'subscriptionRenewed' => AnalyticsEvents.subscriptionCharged,
      'subscriptionRenewedFailed' => AnalyticsEvents.subscriptionChargeFailed,
      'subscriptionRenewalFailed' => AnalyticsEvents.subscriptionChargeFailed,
      'subscriptionRenewalNotified' =>
        AnalyticsEvents.subscriptionRenewalNotified,
      _ => serverName,
    };
  }

  @visibleForTesting
  static Map<String, dynamic> properties(PendingEvent event) {
    final payload = event.payload;
    final rupees = rupeesFrom(payload);
    final trialAmount = payload['plan_trial_amount'];
    final subscriptionAmount = payload['plan_amount'] ?? payload['amount'];
    final props = <String, dynamic>{
      AnalyticsProperties.eventId: event.id,
      AnalyticsProperties.paymentId:
          payload['payment_order_id']?.toString() ??
          payload['payment_id']?.toString() ??
          '',
      AnalyticsProperties.planId: payload['plan_id']?.toString() ?? '',
      AnalyticsProperties.subscriptionId:
          payload['subscription_id']?.toString() ?? '',
      AnalyticsProperties.trialAmount: trialAmount is num ? trialAmount : 0,
      AnalyticsProperties.subscriptionAmount:
          _rupeesFromPayload(subscriptionAmount) ?? rupees ?? 0,
      AnalyticsProperties.mediaURL:
          payload['media_url']?.toString() ??
          payload['plan_video_url']?.toString() ??
          '',
      AnalyticsProperties.planFrequency:
          payload['plan_frequency']?.toString() ??
          payload['frequency']?.toString() ??
          '',
      AnalyticsProperties.planPrice: rupees ?? 0,
      AnalyticsProperties.amount: rupees ?? 0,
      AnalyticsProperties.platform: _platform,
      AnalyticsProperties.subscriptionStatus: AnalyticsValues.free,
    };

    final subscriptionCount =
        payload['subscription_count'] ?? payload['paid_count'];
    if (subscriptionCount is num) {
      props[AnalyticsProperties.subscriptionCount] = subscriptionCount;
    }
    final notificationCount =
        payload['subscription_renewal_notification_count'];
    if (notificationCount is num) {
      props[AnalyticsProperties.subscriptionRenewalNotificationCount] =
          notificationCount;
    }
    final reason = payload['reason'];
    if (reason != null && reason.toString().isNotEmpty) {
      props[AnalyticsProperties.reason] = reason.toString();
    }
    final source = payload['source'];
    if (source != null && source.toString().isNotEmpty) {
      props[AnalyticsProperties.source] = source.toString();
    }

    final recharge = payload['recharge_amount'];
    if (recharge is num && recharge > 0) {
      props[AnalyticsProperties.rechargeAmount] = recharge;
    }

    return props;
  }

  static double? _rupeesFromPayload(Object? raw) {
    if (raw is! num || raw <= 0) return null;
    final value = raw.toDouble();
    if (value >= 100 && value == value.roundToDouble()) {
      return value / 100;
    }
    return value;
  }

  static String get _platform {
    if (kIsWeb) return 'web';
    return Platform.isAndroid ? 'android' : 'ios';
  }

  /// Backend checkout `amount` is usually paise; `plan_trial_amount` is
  /// already rupees when present.
  @visibleForTesting
  static double? rupeesFrom(Map<String, dynamic> payload) {
    final trial = payload['plan_trial_amount'];
    if (trial is num && trial > 0) return trial.toDouble();
    final amount = payload['amount'] ?? payload['plan_amount'];
    if (amount is! num || amount <= 0) return null;
    final value = amount.toDouble();
    if (value >= 100 && value == value.roundToDouble()) {
      return value / 100;
    }
    return value;
  }
}
