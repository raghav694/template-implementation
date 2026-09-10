import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';

/// Routes high-value conversion events to Facebook App Events standard names.
///
/// Mixpanel/Firebase still receive the camelCase taxonomy names via their
/// own services. This class only forwards the Meta-mapped rows:
///   • [AnalyticsEvents.onboardingCompleted] → CompleteRegistration
///   • [AnalyticsEvents.paymentScreen] → AddToCart
///   • [AnalyticsEvents.checkoutStarted] → InitiateCheckout
///   • [AnalyticsEvents.firstAddBalanceSuccess] → StartTrial
///   • [AnalyticsEvents.addBalanceSuccess] → Purchase
///   • [AnalyticsEvents.subscriptionCharged] → Subscribe
///     (backend pending drain only — not checkout)
class FacebookAnalyticsService implements AnalyticsService {
  FacebookAnalyticsService({FacebookAppEvents? client}) : _override = client;

  final FacebookAppEvents? _override;
  FacebookAppEvents? _client;

  FacebookAppEvents? get _fb {
    if (_override != null) return _override;
    try {
      return _client ??= FacebookAppEvents();
    } catch (error, stackTrace) {
      debugPrint('FacebookAnalyticsService: SDK unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    final fb = _fb;
    if (fb == null) return;
    try {
      await fb.setUserID(userId);
    } catch (error, stackTrace) {
      debugPrint('FacebookAnalyticsService.setUserId failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    final fb = _fb;
    if (fb == null) return;

    try {
      switch (name) {
        case AnalyticsEvents.onboardingCompleted:
          await fb.logCompletedRegistration(
            registrationMethod: parameters?[AnalyticsProperties.loginType]
                ?.toString(),
            parameters: _stringParams(parameters),
          );
          return;
        case AnalyticsEvents.paymentScreen:
          await _logAddToCart(fb, parameters);
          return;
        case AnalyticsEvents.checkoutStarted:
          await _logInitiatedCheckout(fb, parameters);
          return;
        case AnalyticsEvents.firstAddBalanceSuccess:
          await _logStartTrial(fb, parameters);
          return;
        case AnalyticsEvents.addBalanceSuccess:
          await _logPurchase(fb, parameters);
          return;
        case AnalyticsEvents.subscriptionCharged:
          await _logSubscribe(fb, parameters);
          return;
        default:
          return;
      }
    } catch (error, stackTrace) {
      debugPrint('FacebookAnalyticsService.logEvent($name) failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _logAddToCart(
    FacebookAppEvents fb,
    Map<String, dynamic>? parameters,
  ) async {
    final price = _readAmount(
      parameters?[AnalyticsProperties.trialAmount],
      fallback: parameters?[AnalyticsProperties.subscriptionAmount],
    );
    if (price == null) return;

    await fb.logAddToCart(
      id: parameters?[AnalyticsProperties.planId]?.toString() ?? '',
      type: parameters?[AnalyticsProperties.planFrequency]?.toString() ?? '',
      currency: 'INR',
      price: price,
      parameters: _stringParams(parameters),
    );
  }

  Future<void> _logInitiatedCheckout(
    FacebookAppEvents fb,
    Map<String, dynamic>? parameters,
  ) async {
    final price = _readAmount(
      parameters?[AnalyticsProperties.trialAmount],
      fallback: parameters?[AnalyticsProperties.subscriptionAmount],
    );
    if (price == null) return;

    await fb.logInitiatedCheckout(
      totalPrice: price,
      currency: 'INR',
      contentType: parameters?[AnalyticsProperties.planFrequency]?.toString(),
      contentId: parameters?[AnalyticsProperties.planId]?.toString(),
      numItems: 1,
      paymentInfoAvailable: false,
      parameters: _stringParams(parameters),
    );
  }

  Future<void> _logStartTrial(
    FacebookAppEvents fb,
    Map<String, dynamic>? parameters,
  ) async {
    final price = _readAmount(
      parameters?[AnalyticsProperties.trialAmount],
      fallback: parameters?[AnalyticsProperties.subscriptionAmount],
    );
    if (price == null) return;

    await fb.logStartTrial(
      currency: 'INR',
      orderId:
          parameters?[AnalyticsProperties.subscriptionId]?.toString() ??
          parameters?[AnalyticsProperties.paymentId]?.toString() ??
          '',
      price: price,
    );
  }

  Future<void> _logPurchase(
    FacebookAppEvents fb,
    Map<String, dynamic>? parameters,
  ) async {
    final price = _readAmount(
      parameters?[AnalyticsProperties.rechargeAmount],
      fallback: _readAmount(
        parameters?[AnalyticsProperties.trialAmount],
        fallback: parameters?[AnalyticsProperties.subscriptionAmount],
      ),
    );
    if (price == null) return;

    await fb.logPurchase(
      amount: price,
      currency: 'INR',
      parameters: _stringParams(parameters),
    );
  }

  Future<void> _logSubscribe(
    FacebookAppEvents fb,
    Map<String, dynamic>? parameters,
  ) async {
    final price = _readAmount(
      parameters?[AnalyticsProperties.subscriptionAmount],
      fallback: parameters?[AnalyticsProperties.trialAmount],
    );
    if (price == null) return;

    final orderId =
        parameters?[AnalyticsProperties.subscriptionId]?.toString() ??
        parameters?[AnalyticsProperties.paymentId]?.toString() ??
        parameters?[AnalyticsProperties.eventId]?.toString() ??
        '';

    await fb.logSubscribe(
      price: price,
      currency: 'INR',
      orderId: orderId,
      parameters: _stringParams(parameters),
    );
  }

  static double? _readAmount(Object? primary, {Object? fallback}) {
    final primaryValue = _positiveNum(primary);
    if (primaryValue != null) return primaryValue;
    return _positiveNum(fallback);
  }

  static double? _positiveNum(Object? raw) {
    if (raw == null) return null;
    double? value;
    if (raw is num) {
      value = raw.toDouble();
    } else if (raw is String) {
      value = double.tryParse(raw);
    }
    if (value == null || value <= 0 || value.isNaN || value.isInfinite) {
      return null;
    }
    return value;
  }

  static Map<String, dynamic>? _stringParams(Map<String, dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) return null;
    return parameters.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
  }

  @override
  Future<void> reset() async {
    final fb = _fb;
    if (fb == null) return;
    try {
      await fb.clearUserID();
    } catch (error, stackTrace) {
      debugPrint('FacebookAnalyticsService.reset failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setUserProperty(String name, String value) async {}

  @override
  Future<void> setUserProfileProperty(String name, dynamic value) async {}

  @override
  Future<void> setUserProfilePropertyOnce(String name, dynamic value) async {}

  @override
  Future<void> incrementUserProperty(String name, {double by = 1}) async {}

  @override
  Future<void> setSuperProperty(String name, dynamic value) async {}

  @override
  Future<void> logScreenView(String screenName) async {}
}
