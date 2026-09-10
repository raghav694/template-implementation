import 'package:app_template/core/analytics/analytics_service.dart';

class RecordingAnalyticsService implements AnalyticsService {
  final logged = <({String name, Map<String, dynamic>? parameters})>[];
  final onceProperties = <String, dynamic>{};
  Object? throwOnLog;

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    if (throwOnLog != null) throw throwOnLog!;
    logged.add((name: name, parameters: parameters));
  }

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}

  @override
  Future<void> setUserProfileProperty(String name, dynamic value) async {}

  @override
  Future<void> setUserProfilePropertyOnce(String name, dynamic value) async {
    onceProperties.putIfAbsent(name, () => value);
  }

  @override
  Future<void> incrementUserProperty(String name, {double by = 1}) async {}

  @override
  Future<void> setSuperProperty(String name, dynamic value) async {}

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> reset() async {}
}
