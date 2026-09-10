import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/paywall/domain/entities/entitlement.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, Entitlement>> getEntitlement(String userId);

  Future<Either<Failure, Subscription?>> getSubscription(String userId);

  Future<Either<Failure, Unit>> cancelSubscription(String userId);
}
