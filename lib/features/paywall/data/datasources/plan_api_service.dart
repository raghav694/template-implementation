import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:app_template/core/network/api_routes.dart';
import 'package:app_template/features/paywall/data/models/plan_dto.dart';

part 'plan_api_service.g.dart';

/// Legacy Heimdall catalog. Paywall plans now come from Capslock Payments
/// via PlanRemoteDataSourceImpl; this service is unused.
@RestApi()
abstract class PlanApiService {
  factory PlanApiService(Dio dio) = _PlanApiService;

  @GET(ApiRoutes.planById)
  Future<PlanDto> fetchPlan(@Path('id') String planId);

  @GET(ApiRoutes.plans)
  Future<PlansResponse> fetchPlans({@Query('source') String? source});
}
