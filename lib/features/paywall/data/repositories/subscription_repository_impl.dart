import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/paywall/data/datasources/subscription_remote_datasource.dart';
import 'package:app_template/features/paywall/domain/entities/entitlement.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';
import 'package:app_template/features/paywall/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._remote);

  final SubscriptionRemoteDataSource _remote;

  @override
  Future<Either<Failure, Entitlement>> getEntitlement(String userId) async {
    try {
      final subscription = await _remote.getSubscription(userId);
      if (subscription != null && subscription.isActive) {
        return Right(
          Entitlement.premium(
            expiresAt: subscription.effectiveExpiresAt,
            plan: subscription.plan,
            status: subscription.status,
          ),
        );
      }
      return Right(Entitlement.free());
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Subscription?>> getSubscription(String userId) async {
    try {
      return Right(await _remote.getSubscription(userId));
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelSubscription(String userId) async {
    try {
      await _remote.cancelSubscription(userId);
      return const Right(unit);
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }
}
