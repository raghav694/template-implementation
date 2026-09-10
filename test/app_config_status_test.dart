import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads snake_case flags from a wrapped payload', () {
    final status = AppConfigStatus.fromResponse({
      'data': {
        'force_update': true,
        'is_app_under_maintenance': true,
        'title': 'Down',
        'message': 'Back soon',
      },
    });

    expect(status.forceUpdate, isTrue);
    expect(status.isUnderMaintenance, isTrue);
    expect(status.title, 'Down');
    expect(status.message, 'Back soon');
  });

  test('treats 1 / "true" as bool flags', () {
    final status = AppConfigStatus.fromJson({
      'force_update': 1,
      'is_app_under_maintenance': 'true',
    });

    expect(status.forceUpdate, isTrue);
    expect(status.isUnderMaintenance, isTrue);
  });

  test('defaults missing flags to false', () {
    final status = AppConfigStatus.fromResponse(<String, dynamic>{});
    expect(status.forceUpdate, isFalse);
    expect(status.isUnderMaintenance, isFalse);
  });

  test('mergedWith ORs flags and prefers overlay copy', () {
    const remote = AppConfigStatus(
      forceUpdate: true,
      title: 'RC title',
      message: 'RC body',
    );
    const api = AppConfigStatus(isUnderMaintenance: true, title: 'API title');

    final merged = remote.mergedWith(api);

    expect(merged.forceUpdate, isTrue);
    expect(merged.isUnderMaintenance, isTrue);
    expect(merged.title, 'API title');
    expect(merged.message, 'RC body');
  });
}
