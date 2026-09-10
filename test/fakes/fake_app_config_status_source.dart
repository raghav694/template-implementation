import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:app_template/core/app_update/app_config_status_source.dart';

class FakeAppConfigStatusSource implements AppConfigStatusSource {
  FakeAppConfigStatusSource([this.next = AppConfigStatus.idle]);

  AppConfigStatus next;
  int fetchCount = 0;

  @override
  Future<AppConfigStatus> fetch() async {
    fetchCount += 1;
    return next;
  }
}
