import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:app_template/core/app_update/app_config_status_source.dart';
import 'package:app_template/core/app_update/config_api_service.dart';
import 'package:app_template/core/network/app_api_client.dart';

/// `GET /api/v1/config/status`. Throws when the endpoint is missing or down.
class AppConfigStatusSourceImpl implements AppConfigStatusSource {
  AppConfigStatusSourceImpl(this._config, this._client);

  final ConfigApiService _config;
  final AppApiClient _client;

  @override
  Future<AppConfigStatus> fetch() async {
    return _client.run(_config.getStatus);
  }
}
