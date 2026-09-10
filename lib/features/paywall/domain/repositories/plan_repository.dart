import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';

abstract class PlanRepository {
  Future<Either<Failure, Plan>> getPlan(String planId);

  Future<Either<Failure, List<Plan>>> listPlans({String? source});
}
