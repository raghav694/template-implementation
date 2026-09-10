import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:app_template/core/app_update/merged_app_config_status_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_app_config_status_source.dart';

void main() {
  test('ORs Remote Config with a successful config API overlay', () async {
    final source = MergedAppConfigStatusSource(
      remoteConfig: FakeAppConfigStatusSource(
        const AppConfigStatus(forceUpdate: true),
      ),
      api: FakeAppConfigStatusSource(
        const AppConfigStatus(isUnderMaintenance: true, title: 'Down'),
      ),
    );

    final status = await source.fetch();

    expect(status.forceUpdate, isTrue);
    expect(status.isUnderMaintenance, isTrue);
    expect(status.title, 'Down');
  });

  test('keeps Remote Config when the config API fails', () async {
    final source = MergedAppConfigStatusSource(
      remoteConfig: FakeAppConfigStatusSource(
        const AppConfigStatus(forceUpdate: true, title: 'RC'),
      ),
      api: _ThrowingAppConfigStatusSource(),
    );

    final status = await source.fetch();

    expect(status.forceUpdate, isTrue);
    expect(status.title, 'RC');
  });
}

class _ThrowingAppConfigStatusSource extends FakeAppConfigStatusSource {
  _ThrowingAppConfigStatusSource() : super();

  @override
  Future<AppConfigStatus> fetch() async {
    throw Exception('config API down');
  }
}
