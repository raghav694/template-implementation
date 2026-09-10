import 'package:in_app_update/in_app_update.dart';

class StoreUpdateInfo {
  const StoreUpdateInfo({
    required this.updateAvailable,
    required this.immediateAllowed,
    required this.flexibleAllowed,
  });

  static const none = StoreUpdateInfo(
    updateAvailable: false,
    immediateAllowed: false,
    flexibleAllowed: false,
  );

  final bool updateAvailable;
  final bool immediateAllowed;
  final bool flexibleAllowed;
}

enum StoreUpdateResult { success, userDenied, other }

/// Play Core in-app updates. No-op implementations belong in tests.
abstract class PlayInAppUpdater {
  Future<StoreUpdateInfo> check();

  Future<StoreUpdateResult> performImmediate();

  Future<StoreUpdateResult> startFlexible();

  Future<void> completeFlexible();
}

class PlayInAppUpdaterImpl implements PlayInAppUpdater {
  const PlayInAppUpdaterImpl();

  @override
  Future<StoreUpdateInfo> check() async {
    final info = await InAppUpdate.checkForUpdate();
    return StoreUpdateInfo(
      updateAvailable:
          info.updateAvailability == UpdateAvailability.updateAvailable,
      immediateAllowed: info.immediateUpdateAllowed,
      flexibleAllowed: info.flexibleUpdateAllowed,
    );
  }

  @override
  Future<StoreUpdateResult> performImmediate() async {
    return _map(await InAppUpdate.performImmediateUpdate());
  }

  @override
  Future<StoreUpdateResult> startFlexible() async {
    return _map(await InAppUpdate.startFlexibleUpdate());
  }

  @override
  Future<void> completeFlexible() => InAppUpdate.completeFlexibleUpdate();

  static StoreUpdateResult _map(AppUpdateResult result) {
    switch (result) {
      case AppUpdateResult.success:
        return StoreUpdateResult.success;
      case AppUpdateResult.userDeniedUpdate:
        return StoreUpdateResult.userDenied;
      case AppUpdateResult.inAppUpdateFailed:
        return StoreUpdateResult.other;
    }
  }
}
