import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/paywall/data/repositories/subscription_repository_impl.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_subscription_remote_datasource.dart';

void main() {
  const active = Subscription(
    userId: 'user-1',
    status: 'active',
    plan: 'monthly',
  );
  const initiated = Subscription(
    userId: 'user-1',
    status: 'initiated',
    plan: 'monthly',
  );

  test('maps an active subscription to premium entitlement', () async {
    final repo = SubscriptionRepositoryImpl(
      FakeSubscriptionRemoteDataSource(subscription: active),
    );

    final result = await repo.getEntitlement('user-1');
    final entitlement = result.fold((_) => null, (value) => value);

    expect(entitlement?.isPremium, isTrue);
    expect(entitlement?.plan, 'monthly');
    expect(entitlement?.status, 'active');
  });

  test('treats initiated (Capslock PENDING) as free', () async {
    final repo = SubscriptionRepositoryImpl(
      FakeSubscriptionRemoteDataSource(subscription: initiated),
    );

    final result = await repo.getEntitlement('user-1');
    final entitlement = result.fold((_) => null, (value) => value);

    expect(entitlement?.isPremium, isFalse);
  });

  test('treats a missing subscription as free', () async {
    final repo = SubscriptionRepositoryImpl(FakeSubscriptionRemoteDataSource());

    final result = await repo.getEntitlement('user-1');
    final entitlement = result.fold((_) => null, (value) => value);

    expect(entitlement?.isPremium, isFalse);
    expect(entitlement?.status, 'free');
  });

  test('maps datasource errors onto failures', () async {
    final repo = SubscriptionRepositoryImpl(
      FakeSubscriptionRemoteDataSource(
        getError: const NetworkException('offline'),
      ),
    );

    final result = await repo.getSubscription('user-1');
    expect(result.isLeft(), isTrue);
    expect(
      result.fold((failure) => failure, (_) => null),
      isA<NetworkFailure>(),
    );
  });

  test('cancels through the datasource', () async {
    final remote = FakeSubscriptionRemoteDataSource(subscription: active);
    final repo = SubscriptionRepositoryImpl(remote);

    final result = await repo.cancelSubscription('user-1');

    expect(result.isRight(), isTrue);
    expect(remote.cancelCalls, 1);
  });
}
