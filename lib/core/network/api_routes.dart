/// REST paths from the host root.
/// App APIs (`/api/v1/...`) use [AppConfig.apiBaseUrl].
/// Auth APIs (`/public/tenants/{tenantCode}/...`) use [AppConfig.authOrigin].
class ApiRoutes {
  ApiRoutes._();

  static const String _v1 = '/api/v1';
  static const String _publicTenants = '/public/tenants';

  static const String sendOtp = '$_publicTenants/{tenantCode}/otp/send';
  static const String verifyOtp = '$_publicTenants/{tenantCode}/otp/verify';
  static const String refreshToken =
      '$_publicTenants/{tenantCode}/token/refresh';
  static const String profileByPhone = '$_publicTenants/{tenantCode}/profile';
  static const String profileByUserId =
      '$_publicTenants/{tenantCode}/users/{userId}';

  static const String truecaller =
      '$_publicTenants/{tenantCode}/truecaller/verify';

  static String refreshTokenFor(String tenantCode) =>
      '$_publicTenants/$tenantCode/token/refresh';

  /// 401s on these paths must not trigger a refresh retry.
  static bool isUnauthenticatedAuthPath(String path) {
    return path.contains('/otp/send') ||
        path.contains('/otp/verify') ||
        path.contains('/token/refresh') ||
        path.contains('/truecaller');
  }

  static const String plans = '$_v1/plans';
  static const String planById = '$_v1/plans/{id}';
  static String plan(String planId) => '$_v1/plans/$planId';
  static const String activePlan = '$_v1/plans/active';

  static const String pendingEvents = '$_v1/events/pending';
  static const String markEventDonePath = '$_v1/events/{id}/done';
  static String markEventDone(String eventId) => '$_v1/events/$eventId/done';

  /// Short-link expand. Body: `{ "link": "...", "short_id": "..." }`.
  /// Response: `{ "original_url": "https://…/payment?planId=…" }`.
  static const String resolveDeeplink = '$_v1/deeplinks/resolve';

  /// Unauthenticated app flags: `force_update`, `is_app_under_maintenance`.
  static const String appConfigStatus = '$_v1/config/status';
}
