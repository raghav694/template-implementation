import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/growthbook/growthbook_service.dart';
import 'package:app_template/core/state/async_value.dart';
import 'package:app_template/features/analytics/purchase_success_reporter.dart';
import 'package:app_template/features/paywall/domain/entities/entitlement.dart';
import 'package:app_template/features/paywall/domain/usecases/subscription_usecases.dart';

class EntitlementCubit extends Cubit<AsyncValue<Entitlement>> {
  EntitlementCubit({
    AnalyticsService? analytics,
    PurchaseSuccessReporter? purchaseReporter,
    GrowthBookService? growthBook,
    GetSubscriptionUseCase? getSubscription,
  }) : _analytics = analytics,
       _purchaseReporter = purchaseReporter,
       _growthBook = growthBook,
       _getSubscription = getSubscription,
       super(const AsyncLoading());

  final AnalyticsService? _analytics;
  final PurchaseSuccessReporter? _purchaseReporter;
  final GrowthBookService? _growthBook;
  final GetSubscriptionUseCase? _getSubscription;

  /// Profile-based access, then Capslock `validity_end_at` when payments
  /// are configured. A past validity end revokes premium even if profile
  /// `entitlement` has not flipped yet.
  ///
  /// On first resolve, stay loading until Capslock returns so login does not
  /// send a still-premium profile to Home before the overlay (Vokey). Later
  /// refreshes keep the current entitlement until the fetch completes.
  Future<void> refreshFor({
    required String userId,
    required bool isPremium,
    required bool hasPurchased,
    DateTime? expiresAt,
  }) async {
    final getSubscription = _getSubscription;
    if (getSubscription == null || !AppConfig.hasPaymentsConfig) {
      apply(
        isPremium: isPremium,
        hasPurchased: hasPurchased,
        expiresAt: expiresAt,
        userId: userId,
      );
      return;
    }

    final alreadyResolved = state is AsyncData<Entitlement>;
    if (alreadyResolved) {
      apply(
        isPremium: isPremium,
        hasPurchased: hasPurchased,
        expiresAt: expiresAt,
        userId: userId,
      );
    }

    final result = await getSubscription(
      GetSubscriptionParams(userId: userId),
    );
    if (isClosed) return;
    result.fold((_) {
      apply(
        isPremium: isPremium,
        hasPurchased: hasPurchased,
        expiresAt: expiresAt,
        userId: userId,
      );
    }, (subscription) {
      if (subscription == null) {
        apply(
          isPremium: isPremium,
          hasPurchased: hasPurchased,
          expiresAt: expiresAt,
          userId: userId,
        );
        return;
      }
      apply(
        isPremium: subscription.isActive,
        hasPurchased: true,
        expiresAt: subscription.effectiveExpiresAt,
        plan: subscription.plan,
        status: subscription.status,
        userId: userId,
      );
    });
  }

  void apply({
    required bool isPremium,
    bool hasPurchased = false,
    DateTime? expiresAt,
    String? plan,
    String? status,
    String? userId,
  }) {
    final entitlement = Entitlement(
      isPremium: isPremium,
      hasPurchased: hasPurchased,
      expiresAt: expiresAt,
      plan: plan,
      status: status ?? (isPremium ? 'active' : 'free'),
    );
    emit(AsyncData(entitlement));
    _growthBook?.setUser(userId: userId, isPremium: isPremium);
    final id = userId;
    if (id != null && id.isNotEmpty) {
      unawaited(_syncAnalytics(id, entitlement));
    }
  }

  void clear() => emit(const AsyncLoading());

  Future<void> _syncAnalytics(String userId, Entitlement entitlement) async {
    final analytics = _analytics;
    if (analytics != null) {
      await analytics.setUserProperty(
        AnalyticsUserProperties.entitlement,
        entitlement.isPremium ? AnalyticsValues.premium : AnalyticsValues.free,
      );
      await analytics.setSuperProperty(
        AnalyticsSuperProperties.subscriptionStatus,
        entitlement.isPremium ? AnalyticsValues.premium : AnalyticsValues.free,
      );
      final plan = entitlement.plan;
      if (plan != null && plan.isNotEmpty) {
        await analytics.setUserProperty(
          AnalyticsUserProperties.subscriptionPlan,
          plan,
        );
      }
    }
    if (entitlement.isPremium) {
      await _purchaseReporter?.flushOnPremiumResume(userId: userId);
    }
  }
}
