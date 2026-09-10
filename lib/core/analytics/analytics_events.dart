// Analytics event names, property keys, and typed values.
// Never use raw strings in feature code — always reference these constants.

class AnalyticsEvents {
  AnalyticsEvents._();

  static const String firstAppOpen = 'firstAppOpen';
  static const String splashScreen = 'splashScreen';
  static const String landingPage = 'landingPage';

  static const String loginScreen = 'loginScreen';
  static const String loginNumberAdded = 'loginNumberAdded';
  static const String otpScreen = 'otpScreen';
  static const String otpRequested = 'otpRequested';
  static const String otpVerified = 'otpVerified';
  static const String otpFailed = 'otpFailed';
  static const String otpResend = 'otpResend';
  static const String truecallerInitiated = 'truecallerInitiated';
  static const String truecallerProceed = 'truecallerProceed';
  static const String truecallerFailed = 'truecallerFailed';
  static const String signOut = 'signOut';
  static const String logout = 'logout';

  /// First login completes onboarding. Properties: [AnalyticsProperties.number],
  /// [AnalyticsProperties.loginType]. Meta CompleteRegistration / GA login.
  static const String onboardingCompleted = 'onboardingCompleted';

  static const String profileScreen = 'profileScreen';
  static const String privacyPolicyScreen = 'privacyPolicyScreen';
  static const String termsOfServiceScreen = 'termsOfServiceScreen';
  static const String refundPolicyScreen = 'refundPolicyScreen';
  static const String helpAndSupportScreen = 'helpAndSupportScreen';

  static const String receivedDeeplink = 'receivedDeeplink';
  static const String resolvedDeeplink = 'resolvedDeeplink';

  /// Snapshot of every enabled GrowthBook feature, keyed by feature name.
  static const String enabledGrowthBookFeatures = 'enabledGrowthBookFeatures';

  static const String paywallShown = 'paywallShown';
  static const String paywallCtaTapped = 'paywallCtaTapped';

  /// Plan + media resolved on paywall. Meta AddToCart / GA add_to_cart.
  static const String paymentScreen = 'paymentScreen';
  static const String paywallDismissed = 'paywallDismissed';

  /// Client-side checkout start. Meta InitiateCheckout / GA begin_checkout.
  static const String checkoutStarted = 'addBalanceInitiated';

  /// Client-side checkout failure.
  static const String paymentFailed = 'addBalanceFailed';

  /// Initiate / UPI-picker failure before a payment exists.
  static const String subscriptionCreationFailed = 'subscriptionCreationFailed';

  /// On-device mandate/checkout success. Mixpanel/Firebase only — Meta
  /// Purchase is fired from [addBalanceSuccess] (client reporter or drain).
  static const String mandateAuthorized = 'checkoutVerified';

  /// Conversion event. Sent once from [PurchaseSuccessReporter] on stream
  /// success (or premium resume), or from the backend pending drain if the
  /// client never flushed. Facebook maps this to Purchase; Google to purchase.
  static const String addBalanceSuccess = 'addBalanceSuccess';

  /// First-ever successful checkout (trial / new subscription). Meta StartTrial
  /// / GA start_trial. Not a renewal — those come from the backend drain.
  static const String firstAddBalanceSuccess = 'firstAddBalanceSuccess';

  /// Recurring charge. Queued by the backend; the app only tracks it when
  /// draining pending events. Meta Subscribe / GA `renew_subscription`.
  static const String subscriptionCharged = 'subscriptionRenewed';

  /// Recurring charge failed. Backend queue may still send
  /// `subscriptionRenewedFailed`; Mixpanel wire name matches the taxonomy table.
  /// Do not log from checkout.
  static const String subscriptionChargeFailed = 'subscriptionRenewalFailed';

  /// Renewal reminder / recorded renewal. Backend drain only.
  static const String subscriptionRenewalNotified =
      'subscriptionRenewalNotified';

  /// User cancelled Autopay from Payment settings (client).
  static const String subscriptionCancel = 'subscriptionCancel';
}

class AnalyticsProperties {
  AnalyticsProperties._();

  static const String reason = 'reason';
  static const String errorCode = 'errorCode';
  static const String source = 'source';
  static const String step = 'step';

  /// Full phone digits, country code included. Never truncated.
  static const String number = 'number';
  static const String loginType = 'loginType';

  static const String planId = 'planId';
  static const String planCategory = 'planCategory';
  static const String planSource = 'planSource';
  static const String trialAmount = 'trialAmount';
  static const String subscriptionAmount = 'subscriptionAmount';
  static const String rechargeAmount = 'rechargeAmount';
  static const String mediaURL = 'mediaURL';
  static const String planFrequency = 'planFrequency';

  /// `normal` (pay as you go) or `subs`.
  static const String rechargeType = 'rechargeType';
  static const String subscriptionCount = 'subscriptionCount';
  static const String subscriptionRenewalNotificationCount =
      'subscriptionRenewalNotificationCount';

  /// Installed UPI app display names (ShantiClub-compatible).
  static const String paymentApps = 'paymentApps';

  /// Selected UPI Android package name.
  static const String selectedPackageName = 'selectedPackageName';

  /// `INTENT` / `QR` on screen load; `link` / `qrcode` on checkout.
  static const String paymentMethod = 'paymentMethod';

  static const String eventId = 'eventId';
  static const String planPrice = 'planPrice';
  static const String amount = 'amount';
  static const String subscriptionId = 'subscriptionId';
  static const String paymentId = 'paymentId';
  static const String deeplink = 'deeplink';
  static const String offerType = 'offerType';
  static const String platform = 'platform';
  static const String subscriptionStatus = 'subscriptionStatus';
  static const String isCancelled = 'isCancelled';
  static const String triggerSource = 'triggerSource';
  static const String timeOnPaywallSeconds = 'timeOnPaywallSeconds';
  static const String status = 'status';
  static const String paidCount = 'paidCount';
  static const String remainingCount = 'remainingCount';

  /// `true` when [AnalyticsEvents.enabledGrowthBookFeatures] fires at login.
  static const String isInit = 'isInit';
}

class AnalyticsValues {
  AnalyticsValues._();

  static const String otpRequest = 'otpRequest';
  static const String otpVerify = 'otpVerify';
  static const String loginTypeOtp = 'OTP';
  static const String loginTypeTruecaller = 'Truecaller';
  static const String rechargeTypeNormal = 'normal';
  static const String rechargeTypeSubs = 'subs';
  static const String sourcePaymentSettings = 'paymentSettings';
  static const String free = 'free';
  static const String premium = 'premium';
  static const String profileUpgrade = 'profileUpgrade';
  static const String appRedirect = 'appRedirect';

  /// Screen-load paymentMethod — any installed UPI app vs QR-only.
  static const String paymentMethodIntent = 'INTENT';
  static const String paymentMethodQr = 'QR';

  /// Checkout paymentMethod — UPI intent vs in-app QR.
  static const String paymentMethodLink = 'link';
  static const String paymentMethodQrCode = 'qrcode';
}

class AnalyticsScreens {
  AnalyticsScreens._();

  static const String home = 'home';
  static const String profile = 'profile';
  static const String auth = 'auth';
  static const String paywall = 'paywall';
}

class AnalyticsUserProperties {
  AnalyticsUserProperties._();

  static const String phone = r'$phone';
  static const String email = r'$email';
  static const String name = r'$name';
  static const String signUpDate = 'signUpDate';
  static const String utmSource = 'utmSource';
  static const String utmMedium = 'utmMedium';
  static const String onboardingDeeplink = 'onboardingDeeplink';
  static const String firstSubscriptionDate = 'firstSubscriptionDate';
  static const String subscriptionPlan = 'subscriptionPlan';
  static const String entitlement = 'entitlement';
}

class AnalyticsSuperProperties {
  AnalyticsSuperProperties._();

  static const String platform = 'platform';
  static const String appVersion = 'appVersion';
  static const String subscriptionStatus = 'subscriptionStatus';

  /// Full phone digits — attached to every subsequent Mixpanel event.
  static const String number = 'number';
}
