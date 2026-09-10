/// How a plan is charged. Autopay and subscription are the same category —
/// recurring. The other category is a one-time payment.
enum PlanCategory {
  /// Recurring Autopay / subscription. Not a Remote Config flag.
  recurring,

  /// Single charge, no mandate / renewal.
  oneTime;

  static PlanCategory parse(String? raw) {
    return tryParse(raw) ?? PlanCategory.recurring;
  }

  static PlanCategory? tryParse(String? raw) {
    final value = raw?.trim().toLowerCase().replaceAll('-', '_');
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'one_time' ||
      'onetime' ||
      'one_time_payment' ||
      'lifetime' ||
      'purchase' => PlanCategory.oneTime,
      'autopay' ||
      'auto_pay' ||
      'upi_autopay' ||
      'subscription' ||
      'subscribe' ||
      'recurring' ||
      'mandate' => PlanCategory.recurring,
      _ => null,
    };
  }

  String get apiValue => switch (this) {
    PlanCategory.recurring => 'recurring',
    PlanCategory.oneTime => 'one_time',
  };
}

/// A catalog plan from Capslock Payments (`GET /v1/tenants/{tenant}/plans`).
class Plan {
  const Plan({
    required this.id,
    required this.label,
    required this.priceAmount,
    required this.billingCycle,
    this.category = PlanCategory.recurring,
    this.currencyCode = 'INR',
    this.originalPriceAmount,
    this.trialDays = 0,
    this.trialAmount,
    this.videoUrl,
  });

  final String id;
  final String label;
  final int priceAmount;
  final int? originalPriceAmount;
  final String billingCycle;
  final PlanCategory category;
  final String currencyCode;
  final int trialDays;
  final int? trialAmount;
  final String? videoUrl;

  bool get hasTrial => trialDays > 0 && trialAmount != null;

  bool get isRecurring => category == PlanCategory.recurring;

  /// Trial amount on first purchase; full [priceAmount] on renewal.
  int get chargeAmount => hasTrial ? trialAmount! : priceAmount;

  int chargeAmountFor({required bool skipTrial}) =>
      skipTrial ? priceAmount : chargeAmount;

  bool showTrialPrice({required bool skipTrial}) => hasTrial && !skipTrial;

  /// Recurring checkout with no trial — hero [priceAmount] instead of the
  /// authorization charge. Used when the user is renewing after cancel.
  Plan withoutTrial() {
    if (!hasTrial) return this;
    return Plan(
      id: id,
      label: label,
      priceAmount: priceAmount,
      originalPriceAmount: originalPriceAmount,
      billingCycle: billingCycle,
      category: category,
      currencyCode: currencyCode,
      videoUrl: videoUrl,
    );
  }

  String get currencySymbol => switch (currencyCode.toUpperCase()) {
    'INR' => '₹',
    'USD' => r'$',
    'EUR' => '€',
    'GBP' => '£',
    _ => '$currencyCode ',
  };

  /// Normalized period word for recurring pricing copy.
  String get billingPeriodLabel {
    if (!isRecurring) return 'once';
    final cycle = billingCycle.trim().toLowerCase();
    if (cycle.startsWith('year') || cycle.startsWith('annual')) return 'year';
    if (cycle.startsWith('quarter')) return 'quarter';
    if (cycle.startsWith('week')) return 'week';
    return 'month';
  }

  int get discountPercent {
    final original = originalPriceAmount;
    if (original == null || original <= 0 || priceAmount >= original) {
      return 0;
    }
    return (((original - priceAmount) / original) * 100).round();
  }

  @override
  bool operator ==(Object other) {
    return other is Plan &&
        other.id == id &&
        other.label == label &&
        other.priceAmount == priceAmount &&
        other.originalPriceAmount == originalPriceAmount &&
        other.billingCycle == billingCycle &&
        other.category == category &&
        other.currencyCode == currencyCode &&
        other.trialDays == trialDays &&
        other.trialAmount == trialAmount &&
        other.videoUrl == videoUrl;
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    priceAmount,
    originalPriceAmount,
    billingCycle,
    category,
    currencyCode,
    trialDays,
    trialAmount,
    videoUrl,
  );
}
