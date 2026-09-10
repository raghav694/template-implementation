import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/paywall/domain/entities/entitlement.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';
import 'package:app_template/features/paywall/domain/repositories/subscription_repository.dart';
import 'package:fpdart/fpdart.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({
    this.entitlement,
    this.subscription,
    this.entitlementFailure,
    this.subscriptionFailure,
    this.cancelFailure,
  });

  Entitlement? entitlement;
  Subscription? subscription;
  Failure? entitlementFailure;
  Failure? subscriptionFailure;
  Failure? cancelFailure;
  var cancelCalls = 0;

  @override
  Future<Either<Failure, Entitlement>> getEntitlement(String userId) async {
    final failure = entitlementFailure;
    if (failure != null) return Left(failure);
    return Right(entitlement ?? Entitlement.free());
  }

  @override
  Future<Either<Failure, Subscription?>> getSubscription(String userId) async {
    final failure = subscriptionFailure;
    if (failure != null) return Left(failure);
    return Right(subscription);
  }

  @override
  Future<Either<Failure, Unit>> cancelSubscription(String userId) async {
    cancelCalls += 1;
    final failure = cancelFailure;
    if (failure != null) return Left(failure);
    return const Right(unit);
  }
}
