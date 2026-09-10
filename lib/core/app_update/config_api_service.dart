import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:app_template/core/network/api_routes.dart';

part 'config_api_service.g.dart';

@RestApi()
abstract class ConfigApiService {
  factory ConfigApiService(Dio dio) = _ConfigApiService;

  @GET(ApiRoutes.appConfigStatus)
  Future<AppConfigStatus> getStatus();
}
