/// Access grant from the auth profile, overlayed with Capslock
/// `validity_end_at` when a billing row exists.
class Entitlement {
  const Entitlement({
    required this.isPremium,
    this.expiresAt,
    this.plan,
    this.status = 'free',
    this.hasPurchased = false,
  });

  final bool isPremium;
  final DateTime? expiresAt;
  final String? plan;
  final String status;
  final bool hasPurchased;

  factory Entitlement.free({bool hasPurchased = false}) =>
      Entitlement(isPremium: false, hasPurchased: hasPurchased);

  factory Entitlement.premium({
    DateTime? expiresAt,
    required String plan,
    String status = 'active',
    bool hasPurchased = true,
  }) => Entitlement(
    isPremium: true,
    expiresAt: expiresAt,
    plan: plan,
    status: status,
    hasPurchased: hasPurchased,
  );
}
