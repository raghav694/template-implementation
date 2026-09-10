/// How the user arrived at `/paywall`.
class PaywallSources {
  PaywallSources._();

  /// First purchase after login. Non-dismissible. Premium users are sent home.
  static const init = 'init';

  /// Payment settings Renew after Autopay cancel (Vokey `source=renew`).
  /// Premium cancelled users stay on this route to checkout.
  static const renew = 'renew';

  /// Lapsed (`free` + `has_purchased`). Router-forced, full price, no trial.
  static const renewal = 'renewal';

  static bool isInit(String? source) =>
      source?.trim().toLowerCase() == init;

  /// Cancelled-but-still-premium checkout from Payment settings.
  static bool isRenew(String? source) =>
      source?.trim().toLowerCase() == renew;

  static bool isLapsed(String? source) =>
      source?.trim().toLowerCase() == renewal;

  /// Settings renew or lapsed paywall — full price, **Renew Now**.
  static bool isRenewal(String? source) => isRenew(source) || isLapsed(source);

  /// Router-forced first-purchase paywall. Close is hidden; premium users
  /// leave this route.
  static bool isGated(String? source) => isInit(source);
}
