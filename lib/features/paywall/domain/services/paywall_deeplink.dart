import 'package:app_template/core/deeplink/incoming_deeplink.dart';

/// Reads a plan id off an incoming paywall / payment URL.
///
/// Supported shapes:
/// - `/paywall?planId=yearly`
/// - `/payment?plan_price_id=yearly&offer_type=DISCOUNT`
/// - `/paywall/yearly`
/// - `{scheme}://paywall?planId=yearly`
/// - `{scheme}://payment?planId=yearly`
/// - `https://{host}/paywall/{id}`
class PaywallDeeplink {
  PaywallDeeplink._();

  static const queryKeys = IncomingDeeplink.planQueryKeys;

  static bool looksLikePaywall(Uri uri) => IncomingDeeplink.isPaymentFlow(uri);

  static String? planIdFrom(Uri uri) => IncomingDeeplink.planIdFrom(uri);
}
