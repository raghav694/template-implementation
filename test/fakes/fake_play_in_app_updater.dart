import 'package:app_template/core/app_update/play_in_app_updater.dart';

class FakePlayInAppUpdater implements PlayInAppUpdater {
  FakePlayInAppUpdater({
    this.info = StoreUpdateInfo.none,
    this.immediateResult = StoreUpdateResult.success,
    this.flexibleResult = StoreUpdateResult.success,
  });

  StoreUpdateInfo info;
  StoreUpdateResult immediateResult;
  StoreUpdateResult flexibleResult;

  int checkCount = 0;
  int immediateCount = 0;
  int flexibleStartCount = 0;
  int flexibleCompleteCount = 0;

  @override
  Future<StoreUpdateInfo> check() async {
    checkCount += 1;
    return info;
  }

  @override
  Future<StoreUpdateResult> performImmediate() async {
    immediateCount += 1;
    return immediateResult;
  }

  @override
  Future<StoreUpdateResult> startFlexible() async {
    flexibleStartCount += 1;
    return flexibleResult;
  }

  @override
  Future<void> completeFlexible() async {
    flexibleCompleteCount += 1;
  }
}
