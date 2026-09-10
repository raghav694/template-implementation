import 'package:app_template/core/payments/payments_config.dart';

/// A Capslock subscription mapped into app vocabulary via [PaymentsConfig].
class Subscription {
  const Subscription({
    required this.userId,
    required this.status,
    required this.plan,
    this.planName,
    this.currentEnd,
    this.chargeAt,
    this.gatewaySubscriptionId,
    this.provider,
    this.paidCount,
    this.remainingCount,
  });

  final String userId;
  final String status;
  final String plan;
  final String? planName;
  final DateTime? currentEnd;
  final DateTime? chargeAt;
  final String? gatewaySubscriptionId;
  final String? provider;
  final int? paidCount;
  final int? remainingCount;

  /// Statuses that keep the user entitled while still within [currentEnd].
  ///
  /// Capslock `CANCELED` maps to `canceled` — Autopay is off, but paid
  /// access continues until [currentEnd] (`validity_end_at`).
  static const _entitledStatuses = {
    'authenticated',
    'active',
    'pending',
    'past_due',
    'canceled',
    'cancelled',
  };

  /// Whether this subscription currently grants premium access.
  ///
  /// `canceled`/`cancelled` stop renewal but keep access until [currentEnd].
  /// Cancelled without a known end date is not premium.
  bool get isActive {
    final normalized = status.trim().toLowerCase();
    if (!_entitledStatuses.contains(normalized)) {
      return false;
    }
    final end = currentEnd;
    final hasKnownEnd = end != null && end.year >= 2000;
    if (hasKnownEnd && !end.isAfter(DateTime.now())) {
      return false;
    }
    if (PaymentsConfig.isCanceled(normalized) && !hasKnownEnd) {
      return false;
    }
    return true;
  }

  DateTime? get effectiveExpiresAt => currentEnd ?? chargeAt;
}
