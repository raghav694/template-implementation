import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/config/app_config.dart';

class MixpanelAnalyticsService implements AnalyticsService {
  MixpanelAnalyticsService();

  Mixpanel? _mixpanel;

  Future<Mixpanel?> _ensureInitialized() async {
    if (_mixpanel != null) return _mixpanel;
    if (!AppConfig.hasMixpanel) return null;

    try {
      _mixpanel = await Mixpanel.init(
        AppConfig.mixpanelToken,
        trackAutomaticEvents: true,
      );

      // Register device-level super properties once at init.
      // These persist in the SDK and are sent with every subsequent event.
      _mixpanel!.registerSuperPropertiesOnce({
        AnalyticsSuperProperties.platform: Platform.isAndroid
            ? 'android'
            : 'ios',
      });
    } catch (error, stackTrace) {
      debugPrint('MixpanelAnalyticsService: init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return _mixpanel;
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    debugPrint(
      'MixpanelAnalyticsService.logEvent Name : $name  with parameters : $parameters',
    );
    final client = await _ensureInitialized();
    if (client == null) return;

    try {
      client.track(name, properties: parameters);
    } catch (error, stackTrace) {
      debugPrint('MixpanelAnalyticsService.logEvent failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    final client = await _ensureInitialized();
    if (client == null) return;

    try {
      client.identify(userId);
    } catch (error, stackTrace) {
      debugPrint('MixpanelAnalyticsService.setUserId failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    final client = await _ensureInitialized();
    if (client == null) return;

    try {
      client.getPeople().set(name, value);
    } catch (error, stackTrace) {
      debugPrint('MixpanelAnalyticsService.setUserProperty failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setUserProfileProperty(String name, dynamic value) async {
    final client = await _ensureInitialized();
    if (client == null) return;

    try {
      client.getPeople().set(name, value);
    } catch (error, stackTrace) {
      debugPrint(
        'MixpanelAnalyticsService.setUserProfileProperty failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setUserProfilePropertyOnce(String name, dynamic value) async {
    final client = await _ensureInitialized();
    if (client == null) return;

    try {
      client.getPeople().setOnce(name, value);
    } catch (error, stackTrace) {
      debugPrint(
        'MixpanelAnalyticsService.setUserProfilePropertyOnce failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> incrementUserProperty(String name, {double by = 1}) async {
    final client = await _ensureInitialized();
    if (client == null) return;

    try {
      client.getPeople().increment(name, by);
    } catch (error, stackTrace) {
      debugPrint(
        'MixpanelAnalyticsService.incrementUserProperty failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setSuperProperty(String name, dynamic value) async {
    final client = await _ensureInitialized();
    if (client == null) return;

    try {
      client.registerSuperProperties({name: value});
    } catch (error, stackTrace) {
      debugPrint('MixpanelAnalyticsService.setSuperProperty failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> logScreenView(String screenName) async {
    // Generic route-change tracking only — the named taxonomy events
    // (landingPage, profileScreen, etc.) are fired explicitly at their own
    // screens and must not be overloaded by every route in the app.
    // await logEvent('screen_view', parameters: {'screen_name': screenName});
  }

  @override
  Future<void> reset() async {
    final client = await _ensureInitialized();
    if (client == null) return;

    try {
      client.reset();
    } catch (error, stackTrace) {
      debugPrint('MixpanelAnalyticsService.reset failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
