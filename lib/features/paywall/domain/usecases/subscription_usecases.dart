import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/failures.dart';
import 'package:app_template/core/utils/usecase.dart';
import 'package:app_template/features/paywall/domain/entities/entitlement.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';
import 'package:app_template/features/paywall/domain/repositories/subscription_repository.dart';

class CheckEntitlementUseCase
    implements UseCase<Entitlement, CheckEntitlementParams> {
  CheckEntitlementUseCase(this.repository);

  final SubscriptionRepository repository;

  @override
  Future<Either<Failure, Entitlement>> call(CheckEntitlementParams params) {
    return repository.getEntitlement(params.userId);
  }
}

class CheckEntitlementParams {
  const CheckEntitlementParams({required this.userId});

  final String userId;
}

class GetSubscriptionUseCase
    implements UseCase<Subscription?, GetSubscriptionParams> {
  GetSubscriptionUseCase(this.repository);

  final SubscriptionRepository repository;

  @override
  Future<Either<Failure, Subscription?>> call(GetSubscriptionParams params) {
    return repository.getSubscription(params.userId);
  }
}

class GetSubscriptionParams {
  const GetSubscriptionParams({required this.userId});

  final String userId;
}

class CancelSubscriptionUseCase
    implements UseCase<Unit, CancelSubscriptionParams> {
  CancelSubscriptionUseCase(this.repository);

  final SubscriptionRepository repository;

  @override
  Future<Either<Failure, Unit>> call(CancelSubscriptionParams params) {
    return repository.cancelSubscription(params.userId);
  }
}

class CancelSubscriptionParams {
  const CancelSubscriptionParams({required this.userId});

  final String userId;
}
