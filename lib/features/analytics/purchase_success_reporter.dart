import 'dart:io' show Platform;

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/features/analytics/pending_purchase_cache.dart';
import 'package:flutter/foundation.dart';

/// Sends `firstAddBalanceSuccess` (first checkout only) and `addBalanceSuccess`
/// once per checkout. A pending row is cached on Continue; success (stream or
/// a later cold start while premium) flushes it and clears the cache.
class PurchaseSuccessReporter {
  PurchaseSuccessReporter(this._cache, this._analytics);

  final PendingPurchaseCache _cache;
  final AnalyticsService _analytics;

  Future<void> markInitiated({
    required String userId,
    required String planId,
    required String subscriptionStatus,
    double? amountInr,
    int? trialAmount,
    int? subscriptionAmount,
    String? mediaURL,
    String? planFrequency,
    bool isPayAsYouGo = false,
    List<String> paymentApps = const [],
    String? selectedPackageName,
    String? paymentMethod,
  }) {
    return _cache.markInitiated(
      userId: userId,
      planId: planId,
      subscriptionStatus: subscriptionStatus,
      amountInr: amountInr,
      trialAmount: trialAmount,
      subscriptionAmount: subscriptionAmount,
      mediaURL: mediaURL,
      planFrequency: planFrequency,
      isPayAsYouGo: isPayAsYouGo,
      paymentApps: paymentApps,
      selectedPackageName: selectedPackageName,
      paymentMethod: paymentMethod,
    );
  }

  Future<void> attachCheckout({
    required String subscriptionId,
    required String paymentId,
    String? planId,
  }) {
    return _cache.attachCheckout(
      subscriptionId: subscriptionId,
      paymentId: paymentId,
      planId: planId,
    );
  }

  /// Stream observed `ACTIVE` / payment success.
  Future<void> flushOnStreamSuccess({
    required String userId,
    required String subscriptionId,
    required String paymentId,
    String? planId,
    double? amountInr,
  }) async {
    await attachCheckout(
      subscriptionId: subscriptionId,
      paymentId: paymentId,
      planId: planId,
    );
    await _flush(
      userId: userId,
      subscriptionId: subscriptionId,
      paymentId: paymentId,
      planId: planId,
      amountInr: amountInr,
    );
  }

  /// Cold start / resume: only if we cached an initiate and the user is now
  /// premium (webhook finished while the app was dead).
  Future<void> flushOnPremiumResume({required String userId}) async {
    if (userId.isEmpty) return;
    await _flush(userId: userId);
  }

  Future<void> _flush({
    required String userId,
    String? subscriptionId,
    String? paymentId,
    String? planId,
    double? amountInr,
  }) async {
    final pending = await _cache.readPending();
    if (pending == null || pending.userId != userId) return;

    final eventId = pending.eventId;
    final resolvedSubscription =
        _nonEmpty(subscriptionId) ?? _nonEmpty(pending.subscriptionId) ?? '';
    final resolvedPayment =
        _nonEmpty(paymentId) ?? _nonEmpty(pending.paymentId) ?? '';
    final resolvedPlan = _nonEmpty(planId) ?? pending.planId;
    final resolvedAmount = amountInr ?? pending.amountInr ?? 0;
    final subscriptionStatus = pending.subscriptionStatus.isNotEmpty
        ? pending.subscriptionStatus
        : AnalyticsValues.free;

    final alreadySent =
        await _cache.hasReported(eventId) ||
        await _cache.hasReported(resolvedSubscription);
    if (alreadySent) {
      await _cache.clearPending();
      return;
    }

    final baseProps = {
      AnalyticsProperties.eventId: eventId,
      AnalyticsProperties.paymentId: resolvedPayment,
      AnalyticsProperties.planId: resolvedPlan,
      AnalyticsProperties.subscriptionId: resolvedSubscription,
      AnalyticsProperties.trialAmount: pending.trialAmount ?? 0,
      AnalyticsProperties.subscriptionAmount: pending.subscriptionAmount ?? 0,
      AnalyticsProperties.mediaURL: pending.mediaURL ?? '',
      AnalyticsProperties.planFrequency: pending.planFrequency ?? '',
      AnalyticsProperties.paymentApps: pending.paymentApps,
      if (pending.selectedPackageName != null &&
          pending.selectedPackageName!.isNotEmpty)
        AnalyticsProperties.selectedPackageName: pending.selectedPackageName,
      if (pending.paymentMethod != null && pending.paymentMethod!.isNotEmpty)
        AnalyticsProperties.paymentMethod: pending.paymentMethod,
      AnalyticsProperties.amount: resolvedAmount,
      AnalyticsProperties.planPrice: resolvedAmount,
      AnalyticsProperties.platform: _platform,
      AnalyticsProperties.subscriptionStatus: subscriptionStatus,
    };

    if (pending.isFirstPurchase) {
      await _analytics.logEvent(
        AnalyticsEvents.firstAddBalanceSuccess,
        parameters: baseProps,
      );
    }

    await _analytics.logEvent(
      AnalyticsEvents.addBalanceSuccess,
      parameters: {
        ...baseProps,
        if (pending.isPayAsYouGo)
          AnalyticsProperties.rechargeAmount: resolvedAmount,
      },
    );

    await _cache.markReported(eventId);
    await _cache.markReported(resolvedSubscription);
    await _cache.clearPending();
  }

  static String get _platform {
    if (kIsWeb) return 'web';
    return Platform.isAndroid ? 'android' : 'ios';
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
