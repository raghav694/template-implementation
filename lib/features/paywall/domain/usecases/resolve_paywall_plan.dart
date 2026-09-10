import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/failures.dart';
import 'package:app_template/core/utils/usecase.dart';
import 'package:app_template/features/paywall/domain/entities/paywall_plan_selection.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/repositories/paywall_config.dart';
import 'package:app_template/features/paywall/domain/repositories/plan_repository.dart';
import 'package:app_template/features/paywall/domain/services/paywall_plan_selector.dart';

class ResolvePaywallPlanParams {
  const ResolvePaywallPlanParams({
    this.deeplinkPlanId,
    this.forcedPlanId,
    this.skipTrial = false,
  });

  final String? deeplinkPlanId;

  /// Cancelled subscription plan from Payment settings. Wins over deeplink /
  /// GrowthBook (Vokey `forcedPaywallPlanIdProvider`).
  final String? forcedPlanId;

  /// Strip trial so checkout charges the base plan price.
  final bool skipTrial;
}

/// Resolves the one plan the paywall should show.
///
/// Same rule as Vokey: deeplink plan id if present, otherwise GrowthBook
/// `paywall_plan_variant` when that feature is on, otherwise Remote Config.
class ResolvePaywallPlanUseCase
    implements UseCase<PaywallPlanSelection, ResolvePaywallPlanParams> {
  ResolvePaywallPlanUseCase({
    required PlanRepository repository,
    required PaywallConfig config,
  }) : _repository = repository,
       _config = config;

  final PlanRepository _repository;
  final PaywallConfig _config;

  @override
  Future<Either<Failure, PaywallPlanSelection>> call(
    ResolvePaywallPlanParams params,
  ) async {
    final skipTrial = params.skipTrial;
    final forcedId = params.forcedPlanId?.trim();
    if (forcedId != null && forcedId.isNotEmpty) {
      final forced = await _planById(forcedId);
      if (forced != null) {
        return Right(
          _selection(
            plan: forced,
            source: PaywallPlanSource.forced,
            requestedPlanId: forcedId,
            skipTrial: true,
          ),
        );
      }
    }

    final deeplinkId = params.deeplinkPlanId?.trim();
    final hasDeeplink = deeplinkId != null && deeplinkId.isNotEmpty;
    final variantId = _config.planVariantId;
    final controlPlanId = _config.controlPlanId;
    final selector = PaywallPlanSelector(controlPlanId: controlPlanId);
    final requested = hasDeeplink ? deeplinkId : variantId;

    if (hasDeeplink) {
      final fromLink = await _planById(deeplinkId);
      if (fromLink != null) {
        return Right(
          _selection(
            plan: fromLink,
            source: PaywallPlanSource.deeplink,
            requestedPlanId: deeplinkId,
            skipTrial: skipTrial,
          ),
        );
      }
    }

    final variant = await _planById(variantId);
    if (variant != null) {
      return Right(
        _selection(
          plan: variant,
          source: PaywallPlanSource.remoteConfig,
          requestedPlanId: requested,
          skipTrial: skipTrial,
        ),
      );
    }

    if (variantId != controlPlanId) {
      final control = await _planById(controlPlanId);
      if (control != null) {
        return Right(
          _selection(
            plan: control,
            source: PaywallPlanSource.control,
            requestedPlanId: requested,
            skipTrial: skipTrial,
          ),
        );
      }
    }

    final catalogResult = await _repository.listPlans();
    return catalogResult.fold(Left.new, (catalog) {
      final selected = selector.select(
        catalog: catalog,
        deeplinkPlanId: deeplinkId,
        variantId: variantId,
      );
      if (selected == null) {
        return const Left(ServerFailure('No plans available'));
      }
      return Right(
        _selection(
          plan: selected.plan,
          source: selected.source,
          requestedPlanId: selected.requestedPlanId,
          skipTrial: skipTrial,
        ),
      );
    });
  }

  static PaywallPlanSelection _selection({
    required Plan plan,
    required PaywallPlanSource source,
    required String requestedPlanId,
    required bool skipTrial,
  }) {
    return PaywallPlanSelection(
      plan: skipTrial ? plan.withoutTrial() : plan,
      source: source,
      requestedPlanId: requestedPlanId,
    );
  }

  Future<Plan?> _planById(String id) async {
    final result = await _repository.getPlan(id);
    return result.fold((_) => null, (plan) => plan);
  }
}
