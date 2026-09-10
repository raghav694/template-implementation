import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/paywall/domain/entities/paywall_plan_selection.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/usecases/resolve_paywall_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_paywall_config.dart';
import 'fakes/fake_plan_repository.dart';

void main() {
  const monthly = Plan(
    id: 'monthly',
    label: 'Monthly',
    priceAmount: 149,
    billingCycle: 'month',
  );
  const yearly = Plan(
    id: 'yearly',
    label: 'Yearly',
    priceAmount: 999,
    billingCycle: 'year',
  );
  const lifetime = Plan(
    id: 'lifetime',
    label: 'Lifetime',
    priceAmount: 2999,
    billingCycle: 'once',
    category: PlanCategory.oneTime,
  );

  test('forced renew plan wins over deeplink and strips trial', () async {
    const trialMonthly = Plan(
      id: 'monthly',
      label: 'Monthly',
      priceAmount: 149,
      billingCycle: 'month',
      trialDays: 3,
      trialAmount: 2,
    );
    final repo = FakePlanRepository(plans: const [trialMonthly, yearly]);
    final useCase = ResolvePaywallPlanUseCase(
      repository: repo,
      config: FakePaywallConfig(planVariantId: 'yearly'),
    );

    final result = await useCase(
      const ResolvePaywallPlanParams(
        deeplinkPlanId: 'yearly',
        forcedPlanId: 'monthly',
      ),
    );
    final selection = result.fold((_) => null, (value) => value);

    expect(selection?.plan.id, 'monthly');
    expect(selection?.plan.hasTrial, isFalse);
    expect(selection?.source, PaywallPlanSource.forced);
    expect(repo.getPlanCalls, ['monthly']);
  });

  test('deeplink plan is fetched without listing the catalog', () async {
    final repo = FakePlanRepository(plans: const [monthly, yearly]);
    final useCase = ResolvePaywallPlanUseCase(
      repository: repo,
      config: FakePaywallConfig(planVariantId: 'monthly'),
    );

    final result = await useCase(
      const ResolvePaywallPlanParams(deeplinkPlanId: 'yearly'),
    );
    final selection = result.fold((_) => null, (value) => value);

    expect(selection?.plan.id, 'yearly');
    expect(selection?.source, PaywallPlanSource.deeplink);
    expect(repo.getPlanCalls, ['yearly']);
    expect(repo.listCalls, 0);
  });

  test('uses Remote Config when no deeplink plan id is present', () async {
    final repo = FakePlanRepository(plans: const [monthly, yearly]);
    final useCase = ResolvePaywallPlanUseCase(
      repository: repo,
      config: FakePaywallConfig(planVariantId: 'yearly'),
    );

    final result = await useCase(const ResolvePaywallPlanParams());
    final selection = result.fold((_) => null, (value) => value);

    expect(selection?.plan.id, 'yearly');
    expect(selection?.source, PaywallPlanSource.remoteConfig);
    expect(repo.getPlanCalls, ['yearly']);
    expect(repo.listCalls, 0);
  });

  test(
    'falls back to Remote Config when the deeplink plan is missing',
    () async {
      final repo = FakePlanRepository(
        plans: const [monthly, yearly],
        getFailures: const {'gone': ServerFailure('missing')},
      );
      final useCase = ResolvePaywallPlanUseCase(
        repository: repo,
        config: FakePaywallConfig(planVariantId: 'yearly'),
      );

      final result = await useCase(
        const ResolvePaywallPlanParams(deeplinkPlanId: 'gone'),
      );
      final selection = result.fold((_) => null, (value) => value);

      expect(selection?.plan.id, 'yearly');
      expect(selection?.source, PaywallPlanSource.remoteConfig);
      expect(repo.listCalls, 0);
    },
  );

  test('falls back to control when the variant fetch fails', () async {
    final repo = FakePlanRepository(
      plans: const [monthly, yearly],
      getFailures: const {'experiment': ServerFailure('missing')},
    );
    final useCase = ResolvePaywallPlanUseCase(
      repository: repo,
      config: FakePaywallConfig(planVariantId: 'experiment'),
    );

    final result = await useCase(const ResolvePaywallPlanParams());
    final selection = result.fold((_) => null, (value) => value);

    expect(selection?.plan.id, 'monthly');
    expect(selection?.source, PaywallPlanSource.control);
    expect(repo.listCalls, 0);
  });

  test('lists the catalog when variant and control are both missing', () async {
    final repo = FakePlanRepository(plans: const [lifetime]);
    final useCase = ResolvePaywallPlanUseCase(
      repository: repo,
      config: FakePaywallConfig(planVariantId: 'gone'),
    );

    final result = await useCase(const ResolvePaywallPlanParams());
    final selection = result.fold((_) => null, (value) => value);

    expect(selection?.plan.id, 'lifetime');
    expect(selection?.source, PaywallPlanSource.catalogFallback);
    expect(repo.listCalls, 1);
  });

  test(
    'a plan-less payment deeplink still uses the Remote Config plan',
    () async {
      final repo = FakePlanRepository(plans: const [yearly, monthly]);
      final useCase = ResolvePaywallPlanUseCase(
        repository: repo,
        config: FakePaywallConfig(planVariantId: 'monthly'),
      );

      final result = await useCase(const ResolvePaywallPlanParams());
      final selection = result.fold((_) => null, (value) => value);

      expect(selection?.plan.id, 'monthly');
      expect(selection?.source, PaywallPlanSource.remoteConfig);
      expect(repo.getPlanCalls, ['monthly']);
      expect(repo.listCalls, 0);
    },
  );

  test('returns a failure when the catalog is empty', () async {
    final repo = FakePlanRepository();
    final useCase = ResolvePaywallPlanUseCase(
      repository: repo,
      config: FakePaywallConfig(planVariantId: 'monthly'),
    );

    final result = await useCase(const ResolvePaywallPlanParams());
    expect(result.isLeft(), isTrue);
  });
}
