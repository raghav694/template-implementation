import 'package:fpdart/fpdart.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/repositories/plan_repository.dart';

class FakePlanRepository implements PlanRepository {
  FakePlanRepository({
    List<Plan> plans = const [],
    Map<String, Failure> getFailures = const {},
    this.listFailure,
  }) : plans = List.of(plans),
       getFailures = Map.of(getFailures);

  final List<Plan> plans;
  final Map<String, Failure> getFailures;
  Failure? listFailure;
  final List<String> getPlanCalls = [];
  var listCalls = 0;
  final listSources = <String?>[];

  @override
  Future<Either<Failure, Plan>> getPlan(String planId) async {
    getPlanCalls.add(planId);
    final failure = getFailures[planId];
    if (failure != null) return Left(failure);
    for (final plan in plans) {
      if (plan.id == planId) return Right(plan);
    }
    return const Left(ServerFailure('Plan configuration not found'));
  }

  @override
  Future<Either<Failure, List<Plan>>> listPlans({String? source}) async {
    listCalls += 1;
    listSources.add(source);
    if (listFailure != null) return Left(listFailure!);
    return Right(List.of(plans));
  }
}
