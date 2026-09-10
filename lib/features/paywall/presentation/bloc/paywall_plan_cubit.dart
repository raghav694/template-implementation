import 'dart:async';

import 'package:app_template/core/state/async_value.dart';
import 'package:app_template/features/paywall/domain/entities/paywall_plan_selection.dart';
import 'package:app_template/features/paywall/domain/usecases/resolve_paywall_plan.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaywallPlanCubit extends Cubit<AsyncValue<PaywallPlanSelection>> {
  PaywallPlanCubit(
    this._resolvePaywallPlan, {
    Duration loadTimeout = const Duration(seconds: 8),
  }) : _loadTimeout = loadTimeout,
       super(const AsyncLoading());

  final Duration _loadTimeout;
  final ResolvePaywallPlanUseCase _resolvePaywallPlan;
  var _generation = 0;
  String? _forcedPlanId;

  /// Checkout override for renew: skip GrowthBook / ads and use the
  /// cancelled subscription's Capslock plan id (Vokey).
  void setForcedPlanId(String? planId) {
    final value = planId?.trim();
    _forcedPlanId = (value == null || value.isEmpty) ? null : value;
  }

  void clearForcedPlanId() => _forcedPlanId = null;

  Future<void> load({String? deeplinkPlanId, bool skipTrial = false}) async {
    final generation = ++_generation;
    emit(const AsyncLoading());
    try {
      final forced = _forcedPlanId;
      final result = await _resolvePaywallPlan(
        ResolvePaywallPlanParams(
          deeplinkPlanId: deeplinkPlanId,
          forcedPlanId: forced,
          skipTrial: skipTrial || (forced != null && forced.isNotEmpty),
        ),
      ).timeout(_loadTimeout);
      if (isClosed || generation != _generation) return;
      result.fold(
        (failure) => emit(AsyncError(failure, StackTrace.current)),
        (selection) => emit(AsyncData(selection)),
      );
    } on TimeoutException {
      if (isClosed || generation != _generation) return;
      emit(
        AsyncError(Exception('Timed out loading plans'), StackTrace.current),
      );
    }
  }
}
