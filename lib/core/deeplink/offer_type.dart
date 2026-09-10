/// Offer attached to a payment deeplink (`offer_type=DISCOUNT|BONUS`).
enum OfferType {
  discount,
  bonus;

  static OfferType? tryParse(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'discount' => OfferType.discount,
      'bonus' => OfferType.bonus,
      _ => null,
    };
  }

  String get apiValue => switch (this) {
    OfferType.discount => 'DISCOUNT',
    OfferType.bonus => 'BONUS',
  };

  String get label => switch (this) {
    OfferType.discount => 'Discount',
    OfferType.bonus => 'Bonus',
  };
}
