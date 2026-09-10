/// Maps Capslock checkout statuses onto the app's subscription vocabulary.
class PaymentsConfig {
  PaymentsConfig._();

  /// Capslock `PENDING` becomes `initiated` so it is not treated as entitled.
  static String toAppSubscriptionStatus(String status) {
    switch (status.trim().toUpperCase()) {
      case 'ACTIVE':
        return 'active';
      case 'PAST_DUE':
        return 'past_due';
      case 'PENDING':
        return 'initiated';
      case 'PAUSED':
        return 'paused';
      case 'SUSPENDED':
        return 'suspended';
      case 'CANCELED':
      case 'CANCELLED':
        return 'canceled';
      default:
        return status.trim().toLowerCase();
    }
  }

  static bool isCanceled(String status) {
    final value = status.trim().toLowerCase();
    return value == 'canceled' || value == 'cancelled';
  }
}
