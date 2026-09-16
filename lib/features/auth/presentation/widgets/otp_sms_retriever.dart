import 'dart:io' show Platform;

import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';

/// Bridges [SmartAuth]'s Android SMS Retriever API into Pinput's
/// [SmsRetriever] interface, so a matched OTP is written straight into the
/// pin field's controller — which is what actually drives both the visual
/// fill and the existing auto-submit logic in `auth_screen.dart` (Pinput
/// listens on the controller itself, not just its own `onChanged` param).
///
/// SMS Retriever is Android-only and requires the SMS to end with this app's
/// 11-character hash string. Configure that hash on the API that sends OTPs.
/// A `null` return here is a normal, silent no-op — manual entry is always
/// the fallback, this is a pure enhancement on top of it.
class OtpSmsRetriever implements SmsRetriever {
  /// Exactly 4 digits — narrower than smart_auth's default 4–8 digit
  /// matcher, since that's the fixed OTP length this template expects.
  static const _codeMatcher = r'\d{4}';

  @override
  bool get listenForMultipleSms => false;

  @override
  Future<String?> getSmsCode() async {
    if (!Platform.isAndroid) return null;

    final result = await SmartAuth.instance.getSmsWithRetrieverApi(
      matcher: _codeMatcher,
    );
    if (!result.hasData) return null;
    return result.data?.code;
  }

  @override
  Future<void> dispose() async {
    if (!Platform.isAndroid) return;
    await SmartAuth.instance.removeSmsRetrieverApiListener();
  }
}
