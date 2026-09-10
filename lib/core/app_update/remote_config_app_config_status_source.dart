import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:app_template/core/app_update/app_config_status_source.dart';
import 'package:app_template/core/remote_config/remote_config_keys.dart';
import 'package:app_template/core/remote_config/remote_config_service.dart';

/// Reads `force_update` / maintenance flags from Firebase Remote Config.
class RemoteConfigAppConfigStatusSource implements AppConfigStatusSource {
  const RemoteConfigAppConfigStatusSource({this.refresh = true});

  /// When true, fetches the latest published values before reading.
  final bool refresh;

  @override
  Future<AppConfigStatus> fetch() async {
    if (refresh) {
      await RemoteConfigService.refresh();
    }
    return read();
  }

  static AppConfigStatus read() {
    final title = RemoteConfigService.getString(
      RemoteConfigKeys.maintenanceTitle,
    ).trim();
    final message = RemoteConfigService.getString(
      RemoteConfigKeys.maintenanceMessage,
    ).trim();
    return AppConfigStatus(
      forceUpdate: RemoteConfigService.getBool(RemoteConfigKeys.forceUpdate),
      isUnderMaintenance: RemoteConfigService.getBool(
        RemoteConfigKeys.isAppUnderMaintenance,
      ),
      title: title.isEmpty ? null : title,
      message: message.isEmpty ? null : message,
    );
  }
}
