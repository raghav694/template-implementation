import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:app_template/core/deeplink/deeplink_api_models.dart';
import 'package:app_template/core/network/api_routes.dart';

part 'deeplink_api_service.g.dart';

@RestApi()
abstract class DeeplinkApiService {
  factory DeeplinkApiService(Dio dio) = _DeeplinkApiService;

  @POST(ApiRoutes.resolveDeeplink)
  Future<ResolveDeeplinkResponse> resolve(@Body() ResolveDeeplinkRequest body);
}
