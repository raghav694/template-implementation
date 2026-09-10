import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';
import 'package:app_template/features/paywall/domain/usecases/subscription_usecases.dart';
import 'package:app_template/features/paywall/presentation/bloc/entitlement_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_subscription_repository.dart';

void main() {
  tearDown(AppConfig.resetForTesting);

  test('refreshFor overlays an expired Capslock validity end as free', () async {
    await AppConfig.initializeForTest(
      Environment.dev,
      envContent: '''
API_BASE_URL=https://dev-api.example.com
PAYMENTS_BASE_URL=https://payments.example.com
PAYMENTS_TENANT_ID=tenant-1
''',
    );

    final cubit = EntitlementCubit(
      getSubscription: GetSubscriptionUseCase(
        FakeSubscriptionRepository(
          subscription: Subscription(
            userId: 'u1',
            status: 'active',
            plan: 'monthly',
            currentEnd: DateTime(2020, 1, 1),
          ),
        ),
      ),
    );

    await cubit.refreshFor(
      userId: 'u1',
      isPremium: true,
      hasPurchased: true,
    );

    final entitlement = cubit.state.valueOrNull;
    expect(entitlement?.isPremium, isFalse);
    expect(entitlement?.hasPurchased, isTrue);
    await cubit.close();
  });

  test('refreshFor keeps profile premium when payments are not configured',
      () async {
    await AppConfig.initializeForTest(
      Environment.dev,
      envContent: 'API_BASE_URL=https://dev-api.example.com\n',
    );

    final cubit = EntitlementCubit(
      getSubscription: GetSubscriptionUseCase(
        FakeSubscriptionRepository(
          subscription: Subscription(
            userId: 'u1',
            status: 'active',
            plan: 'monthly',
            currentEnd: DateTime(2020, 1, 1),
          ),
        ),
      ),
    );

    await cubit.refreshFor(
      userId: 'u1',
      isPremium: true,
      hasPurchased: true,
    );

    expect(cubit.state.valueOrNull?.isPremium, isTrue);
    await cubit.close();
  });

  test('refreshFor keeps profile access when Capslock has no row', () async {
    await AppConfig.initializeForTest(
      Environment.dev,
      envContent: '''
API_BASE_URL=https://dev-api.example.com
PAYMENTS_BASE_URL=https://payments.example.com
PAYMENTS_TENANT_ID=tenant-1
''',
    );

    final cubit = EntitlementCubit(
      getSubscription: GetSubscriptionUseCase(FakeSubscriptionRepository()),
    );

    await cubit.refreshFor(
      userId: 'u1',
      isPremium: true,
      hasPurchased: true,
    );

    expect(cubit.state.valueOrNull?.isPremium, isTrue);
    await cubit.close();
  });

  test('refreshFor keeps cancelled Autopay premium until validity end',
      () async {
    await AppConfig.initializeForTest(
      Environment.dev,
      envContent: '''
API_BASE_URL=https://dev-api.example.com
PAYMENTS_BASE_URL=https://payments.example.com
PAYMENTS_TENANT_ID=tenant-1
''',
    );

    final cubit = EntitlementCubit(
      getSubscription: GetSubscriptionUseCase(
        FakeSubscriptionRepository(
          subscription: Subscription(
            userId: 'u1',
            status: 'canceled',
            plan: 'monthly',
            currentEnd: DateTime.now().add(const Duration(days: 10)),
          ),
        ),
      ),
    );

    await cubit.refreshFor(
      userId: 'u1',
      isPremium: true,
      hasPurchased: true,
    );

    expect(cubit.state.valueOrNull?.isPremium, isTrue);
    expect(cubit.state.valueOrNull?.status, 'canceled');
    await cubit.close();
  });
}
