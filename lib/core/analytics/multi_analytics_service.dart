import 'package:flutter/foundation.dart';

import 'package:app_template/core/analytics/analytics_service.dart';

class MultiAnalyticsService implements AnalyticsService {
  MultiAnalyticsService(this.services);

  final List<AnalyticsService> services;

  Future<void> _fanOut(
    Future<void> Function(AnalyticsService service) action,
  ) async {
    await Future.wait(
      services.map((service) async {
        try {
          await action(service);
        } catch (error, stackTrace) {
          debugPrint(
            'MultiAnalyticsService: ${service.runtimeType} failed: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
      }),
    );
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) {
    return _fanOut((service) => service.logEvent(name, parameters: parameters));
  }

  @override
  Future<void> setUserId(String userId) {
    return _fanOut((service) => service.setUserId(userId));
  }

  @override
  Future<void> setUserProperty(String name, String value) {
    return _fanOut((service) => service.setUserProperty(name, value));
  }

  @override
  Future<void> setUserProfileProperty(String name, dynamic value) {
    return _fanOut((service) => service.setUserProfileProperty(name, value));
  }

  @override
  Future<void> setUserProfilePropertyOnce(String name, dynamic value) {
    return _fanOut(
      (service) => service.setUserProfilePropertyOnce(name, value),
    );
  }

  @override
  Future<void> incrementUserProperty(String name, {double by = 1}) {
    return _fanOut((service) => service.incrementUserProperty(name, by: by));
  }

  @override
  Future<void> setSuperProperty(String name, dynamic value) {
    return _fanOut((service) => service.setSuperProperty(name, value));
  }

  @override
  Future<void> logScreenView(String screenName) {
    return _fanOut((service) => service.logScreenView(screenName));
  }

  @override
  Future<void> reset() {
    return _fanOut((service) => service.reset());
  }
}
