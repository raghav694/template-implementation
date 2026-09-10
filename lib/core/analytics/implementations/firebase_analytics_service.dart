import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService([FirebaseAnalytics? analytics])
    : _analyticsOverride = analytics;

  final FirebaseAnalytics? _analyticsOverride;

  FirebaseAnalytics? get _client {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return _analyticsOverride ?? FirebaseAnalytics.instance;
  }

  Map<String, Object>? _sanitizeParameters(Map<String, dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) {
      return null;
    }

    return parameters.map((key, value) => MapEntry(key, _sanitizeValue(value)));
  }

  Object _sanitizeValue(dynamic value) {
    if (value is num || value is String) {
      return value;
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is Iterable && value is! String) {
      return value.map((item) => item.toString()).join(',');
    }
    return value.toString();
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    final client = _client;
    if (client == null) {
      return;
    }

    try {
      switch (name) {
        case AnalyticsEvents.firstAppOpen:
          await client.logEvent(
            name: 'first_visit',
            parameters: _sanitizeParameters(parameters),
          );
          return;
        case AnalyticsEvents.onboardingCompleted:
          await client.logLogin(
            loginMethod:
                parameters?[AnalyticsProperties.loginType]?.toString() ?? '',
            parameters: _sanitizeParameters(parameters),
          );
          return;
        case AnalyticsEvents.paymentScreen:
          await _logAddToCart(client, parameters);
          return;
        case AnalyticsEvents.checkoutStarted:
          await _logBeginCheckout(client, parameters);
          return;
        case AnalyticsEvents.firstAddBalanceSuccess:
          await client.logEvent(
            name: 'start_trial',
            parameters: _sanitizeParameters(parameters),
          );
          return;
        case AnalyticsEvents.addBalanceSuccess:
          await _logPurchase(client, parameters);
          return;
        case AnalyticsEvents.subscriptionCharged:
          // Backend pending drain only. Checkout must not log this name.
          await client.logEvent(
            name: 'renew_subscription',
            parameters: _sanitizeParameters(parameters),
          );
          return;
        default:
          await client.logEvent(
            name: name,
            parameters: _sanitizeParameters(parameters),
          );
      }
    } catch (error, stackTrace) {
      debugPrint('FirebaseAnalyticsService.logEvent failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _logAddToCart(
    FirebaseAnalytics client,
    Map<String, dynamic>? parameters,
  ) async {
    final planId = parameters?[AnalyticsProperties.planId]?.toString() ?? '';
    final amount = _readAmount(
      parameters?[AnalyticsProperties.trialAmount],
      fallback: parameters?[AnalyticsProperties.subscriptionAmount],
    );

    await client.logAddToCart(
      currency: 'INR',
      value: amount,
      items: planId.isEmpty
          ? null
          : [
              AnalyticsEventItem(
                itemId: planId,
                itemName: planId,
                price: amount,
                quantity: 1,
              ),
            ],
      parameters: _sanitizeParameters(parameters),
    );
  }

  Future<void> _logBeginCheckout(
    FirebaseAnalytics client,
    Map<String, dynamic>? parameters,
  ) async {
    final planId = parameters?[AnalyticsProperties.planId]?.toString() ?? '';
    final amount = _readAmount(
      parameters?[AnalyticsProperties.trialAmount],
      fallback: parameters?[AnalyticsProperties.subscriptionAmount],
    );

    await client.logBeginCheckout(
      currency: 'INR',
      value: amount,
      items: planId.isEmpty
          ? null
          : [
              AnalyticsEventItem(
                itemId: planId,
                itemName: planId,
                price: amount,
                quantity: 1,
              ),
            ],
      parameters: _sanitizeParameters(parameters),
    );
  }

  Future<void> _logPurchase(
    FirebaseAnalytics client,
    Map<String, dynamic>? parameters,
  ) async {
    final amount = _readAmount(
      parameters?[AnalyticsProperties.rechargeAmount],
      fallback: _readAmount(
        parameters?[AnalyticsProperties.trialAmount],
        fallback: parameters?[AnalyticsProperties.subscriptionAmount],
      ),
    );
    final transactionId =
        parameters?[AnalyticsProperties.paymentId]?.toString() ??
        parameters?[AnalyticsProperties.subscriptionId]?.toString() ??
        parameters?[AnalyticsProperties.eventId]?.toString();

    await client.logPurchase(
      currency: 'INR',
      value: amount,
      transactionId: transactionId,
      parameters: _sanitizeParameters(parameters),
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

  @override
  Future<void> setUserId(String userId) async {
    final client = _client;
    if (client == null) {
      return;
    }

    try {
      await client.setUserId(id: userId);
    } catch (error, stackTrace) {
      debugPrint('FirebaseAnalyticsService.setUserId failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Sanitizes a property name to meet Firebase Analytics requirements:
  /// must be 1–24 alphanumeric (or underscore) characters and must not
  /// start with a digit or contain special characters like `$`.
  String _sanitizePropertyName(String name) {
    // Strip leading/trailing `$` signs (e.g. Mixpanel-style "$phone" → "phone")
    var sanitized = name.replaceAll(r'$', '');
    // Replace any remaining non-alphanumeric/non-underscore characters with `_`
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    // Truncate to 24 characters
    if (sanitized.length > 24) sanitized = sanitized.substring(0, 24);
    return sanitized;
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    final client = _client;
    if (client == null) {
      return;
    }

    final sanitizedName = _sanitizePropertyName(name);
    if (sanitizedName.isEmpty) {
      return;
    }

    try {
      await client.setUserProperty(name: sanitizedName, value: value);
    } catch (error, stackTrace) {
      debugPrint('FirebaseAnalyticsService.setUserProperty failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setUserProfileProperty(String name, dynamic value) async {
    // Firebase only supports String user properties; coerce to String.
    await setUserProperty(name, value?.toString() ?? '');
  }

  @override
  Future<void> setUserProfilePropertyOnce(String name, dynamic value) async {
    // Firebase has no "set-once" concept; always write.
    await setUserProperty(name, value?.toString() ?? '');
  }

  @override
  Future<void> incrementUserProperty(String name, {double by = 1}) async {
    // Firebase has no increment API; user profile counters are Mixpanel-only.
  }

  @override
  Future<void> setSuperProperty(String name, dynamic value) async {
    // Firebase has no super-property concept; mirror as a user property.
    await setUserProperty(name, value?.toString() ?? '');
  }

  @override
  Future<void> logScreenView(String screenName) async {
    final client = _client;
    if (client == null) {
      return;
    }

    try {
      await client.logScreenView(screenName: screenName);
    } catch (error, stackTrace) {
      debugPrint('FirebaseAnalyticsService.logScreenView failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> reset() async {
    final client = _client;
    if (client == null) {
      return;
    }

    try {
      await client.setUserId(id: null);
    } catch (error, stackTrace) {
      debugPrint('FirebaseAnalyticsService.reset failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
