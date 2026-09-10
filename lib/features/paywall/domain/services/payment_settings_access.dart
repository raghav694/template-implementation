import 'package:app_template/core/payments/payments_config.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';

/// Cancel vs renew on Payment settings (same rules as Vokey).
///
/// Renew is for Autopay cancelled while [entitlement] is still premium
/// (access until `validity_end_at`). Fully expired users are routed to the
/// paywall by `appRedirect`, not this screen.
class PaymentSettingsAccess {
  PaymentSettingsAccess._();

  static bool isOneTimePlan(Plan? plan) =>
      plan?.category == PlanCategory.oneTime;

  static bool canCancel({
    required bool isPremium,
    required bool isOneTime,
    Subscription? subscription,
  }) {
    if (!isPremium) return false;
    if (isOneTime) return false;
    if (subscription == null) return false;
    if (PaymentsConfig.isCanceled(subscription.status)) return false;
    return true;
  }

  static bool canRenew({
    required bool isPremium,
    required bool isOneTime,
    Subscription? subscription,
  }) {
    if (!isPremium) return false;
    if (isOneTime) return false;
    final status = subscription?.status;
    if (status == null) return false;
    return PaymentsConfig.isCanceled(status);
  }
}
