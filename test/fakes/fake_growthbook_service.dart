import 'package:app_template/core/attribution/utm_data.dart';
import 'package:app_template/core/growthbook/growthbook_service.dart';

class FakeGrowthBookService extends GrowthBookService {
  FakeGrowthBookService({
    this.forceUpdate = false,
    this.planId = '',
    this.enabled = const {},
  });

  final bool forceUpdate;
  final String planId;
  final Map<String, dynamic> enabled;

  UtmData? lastAttribution;
  String? lastUserId;
  bool? lastIsPremium;
  var initializeCount = 0;

  @override
  Future<void> initialize() async {
    initializeCount += 1;
  }

  @override
  Future<void> initializeIfNeeded() => initialize();

  @override
  bool isForceUpdate() => forceUpdate;

  @override
  String conversionPlanId() => planId;

  @override
  Map<String, dynamic> enabledFeatures() => enabled;

  @override
  void applyAttribution(UtmData utm) {
    lastAttribution = utm;
  }

  @override
  void setUser({String? userId, bool? isPremium}) {
    lastUserId = userId;
    lastIsPremium = isPremium;
  }

  @override
  Future<void> prepareForPlanEvaluation({
    String? languageCode,
    String? userId,
    bool? isPremium,
  }) async {
    setUser(userId: userId, isPremium: isPremium);
  }

  @override
  void logDebugState({String? context}) {}
}
