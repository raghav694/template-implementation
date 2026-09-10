import 'package:app_template/core/analytics/analytics_events.dart';

/// Shared auth-funnel properties. [AnalyticsProperties.number] is the full
/// phone (digits only, country code included) — never last-four.
class AuthEventProperties {
  AuthEventProperties._();

  static Map<String, dynamic> otp({
    String? phoneNumber,
    Map<String, dynamic>? extra,
  }) {
    return forLoginType(
      loginType: AnalyticsValues.loginTypeOtp,
      phoneNumber: phoneNumber,
      extra: extra,
    );
  }

  static Map<String, dynamic> truecaller({
    String? phoneNumber,
    Map<String, dynamic>? extra,
  }) {
    return forLoginType(
      loginType: AnalyticsValues.loginTypeTruecaller,
      phoneNumber: phoneNumber,
      extra: extra,
    );
  }

  static Map<String, dynamic> forLoginType({
    required String loginType,
    String? phoneNumber,
    Map<String, dynamic>? extra,
  }) {
    final number = fullNumber(phoneNumber);
    return {
      AnalyticsProperties.loginType: loginType,
      if (number.isNotEmpty) AnalyticsProperties.number: number,
      if (extra != null) ...extra,
    };
  }

  /// Full phone digits (country code included when present). Never truncated.
  static String fullNumber(String? phoneNumber) {
    return phoneNumber?.replaceAll(RegExp(r'\D'), '') ?? '';
  }
}
