import 'package:app_template/core/app_update/app_config_status.dart';

abstract class AppConfigStatusSource {
  Future<AppConfigStatus> fetch();
}
