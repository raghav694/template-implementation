import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:app_template/core/app_update/app_update_service.dart';
import 'package:app_template/core/app_update/play_in_app_updater.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_app_config_status_source.dart';
import 'fakes/fake_growthbook_service.dart';
import 'fakes/fake_play_in_app_updater.dart';

void main() {
  const availableImmediate = StoreUpdateInfo(
    updateAvailable: true,
    immediateAllowed: true,
    flexibleAllowed: true,
  );

  test('launch does not prompt Play unless force-update is on', () async {
    final play = FakePlayInAppUpdater(info: availableImmediate);
    final service = AppUpdateService(
      statusSource: FakeAppConfigStatusSource(),
      playUpdater: play,
      isAndroid: () => true,
      onImmediateUpdateInstalled: () {},
    );

    await service.checkOnLaunch();

    expect(play.checkCount, 0);
    expect(play.immediateCount, 0);
  });

  test(
    'launch uses flexible when force is on and immediate is not allowed',
    () async {
      final play = FakePlayInAppUpdater(
        info: const StoreUpdateInfo(
          updateAvailable: true,
          immediateAllowed: false,
          flexibleAllowed: true,
        ),
      );
      final service = AppUpdateService(
        statusSource: FakeAppConfigStatusSource(
          const AppConfigStatus(forceUpdate: true),
        ),
        playUpdater: play,
        isAndroid: () => true,
        onImmediateUpdateInstalled: () {},
      );

      await service.checkOnLaunch();

      expect(play.flexibleStartCount, 1);
      expect(play.flexibleCompleteCount, 1);
      expect(play.immediateCount, 0);
    },
  );

  test('launch retries immediate when force update is denied', () async {
    final play = FakePlayInAppUpdater(
      info: const StoreUpdateInfo(
        updateAvailable: true,
        immediateAllowed: true,
        flexibleAllowed: false,
      ),
      immediateResult: StoreUpdateResult.userDenied,
    );
    final service = AppUpdateService(
      statusSource: FakeAppConfigStatusSource(
        const AppConfigStatus(forceUpdate: true),
      ),
      playUpdater: play,
      isAndroid: () => true,
      onImmediateUpdateInstalled: () {},
    );

    await service.checkOnLaunch();

    expect(play.immediateCount, 4);
  });

  test('resume does not prompt Play unless force_update is true', () async {
    final play = FakePlayInAppUpdater(info: availableImmediate);
    final service = AppUpdateService(
      statusSource: FakeAppConfigStatusSource(),
      playUpdater: play,
      isAndroid: () => true,
      onImmediateUpdateInstalled: () {},
    );

    await service.checkForceUpdate();

    expect(play.checkCount, 0);
    expect(play.immediateCount, 0);
  });

  test('resume prompts Play when force_update is true', () async {
    final play = FakePlayInAppUpdater(
      info: const StoreUpdateInfo(
        updateAvailable: true,
        immediateAllowed: true,
        flexibleAllowed: false,
      ),
    );
    var exited = false;
    final service = AppUpdateService(
      statusSource: FakeAppConfigStatusSource(
        const AppConfigStatus(forceUpdate: true),
      ),
      playUpdater: play,
      isAndroid: () => true,
      onImmediateUpdateInstalled: () => exited = true,
    );

    await service.checkForceUpdate();

    expect(play.immediateCount, 1);
    expect(exited, isTrue);
  });

  test('GrowthBook forceUpdate prompts Play even when RC is off', () async {
    final play = FakePlayInAppUpdater(
      info: const StoreUpdateInfo(
        updateAvailable: true,
        immediateAllowed: true,
        flexibleAllowed: false,
      ),
    );
    var exited = false;
    final service = AppUpdateService(
      statusSource: FakeAppConfigStatusSource(),
      playUpdater: play,
      growthBook: FakeGrowthBookService(forceUpdate: true),
      isAndroid: () => true,
      onImmediateUpdateInstalled: () => exited = true,
    );

    await service.checkOnLaunch();

    expect(play.immediateCount, 1);
    expect(exited, isTrue);
    expect(service.status.value.forceUpdate, isTrue);
  });

  test('does not talk to Play off Android', () async {
    final play = FakePlayInAppUpdater(info: availableImmediate);
    final service = AppUpdateService(
      statusSource: FakeAppConfigStatusSource(
        const AppConfigStatus(forceUpdate: true),
      ),
      playUpdater: play,
      isAndroid: () => false,
      onImmediateUpdateInstalled: () {},
    );

    await service.checkOnLaunch();
    await service.checkForceUpdate();

    expect(play.checkCount, 0);
  });
}
