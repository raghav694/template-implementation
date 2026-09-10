import 'package:app_template/features/paywall/domain/entities/plan.dart';

abstract class PlanRemoteDataSource {
  Future<Plan> fetchPlan(String planId);

  Future<List<Plan>> fetchPlans({String? source});
}
