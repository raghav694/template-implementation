import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:app_template/core/app_update/app_config_status_source.dart';

/// Remote Config is always applied. A successful config API overlay is ORed
/// in so either Firebase or the backend can force an update / maintenance.
class MergedAppConfigStatusSource implements AppConfigStatusSource {
  const MergedAppConfigStatusSource({
    required this.remoteConfig,
    required this.api,
  });

  final AppConfigStatusSource remoteConfig;
  final AppConfigStatusSource api;

  @override
  Future<AppConfigStatus> fetch() async {
    final fromRemoteConfig = await remoteConfig.fetch();
    try {
      return fromRemoteConfig.mergedWith(await api.fetch());
    } catch (_) {
      return fromRemoteConfig;
    }
  }
}
