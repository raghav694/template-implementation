import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/repositories/plan_repository.dart';
import 'package:app_template/features/paywall/data/datasources/plan_remote_datasource.dart';

class PlanRepositoryImpl implements PlanRepository {
  PlanRepositoryImpl(this._remote);

  final PlanRemoteDataSource _remote;

  @override
  Future<Either<Failure, Plan>> getPlan(String planId) {
    return _guard(() => _remote.fetchPlan(planId));
  }

  @override
  Future<Either<Failure, List<Plan>>> listPlans({String? source}) {
    return _guard(() => _remote.fetchPlans(source: source));
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }
}
