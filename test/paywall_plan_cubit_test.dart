import 'dart:async';

import 'package:app_template/core/error/failures.dart';
import 'package:app_template/core/state/async_value.dart';
import 'package:app_template/features/paywall/domain/entities/paywall_plan_selection.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/repositories/plan_repository.dart';
import 'package:app_template/features/paywall/domain/usecases/resolve_paywall_plan.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_plan_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'fakes/fake_paywall_config.dart';

class _HangingPlanRepository implements PlanRepository {
  @override
  Future<Either<Failure, Plan>> getPlan(String planId) =>
      Completer<Either<Failure, Plan>>().future;

  @override
  Future<Either<Failure, List<Plan>>> listPlans({String? source}) =>
      Completer<Either<Failure, List<Plan>>>().future;
}

void main() {
  test('emits an error instead of spinning when plans never return', () async {
    final cubit = PaywallPlanCubit(
      ResolvePaywallPlanUseCase(
        repository: _HangingPlanRepository(),
        config: FakePaywallConfig(),
      ),
      loadTimeout: const Duration(milliseconds: 20),
    );

    await cubit.load();

    expect(cubit.state, isA<AsyncError<PaywallPlanSelection>>());
    await cubit.close();
  });
}
