/// Dedups `loginScreen` across the multiple `AuthScreen` remounts go_router's
/// redirect can produce while a cold-start auth stream settles, while still
/// allowing it to fire again after a genuine sign-out.
class LoginScreenAnalyticsGuard {
  LoginScreenAnalyticsGuard._();

  static bool loggedThisVisit = false;

  static void reset() => loggedThisVisit = false;
}

/// Dedups Truecaller auto-launch across go_router remounts; reset on sign-out.
class TruecallerAutoLaunchGuard {
  TruecallerAutoLaunchGuard._();

  static bool launchedThisVisit = false;

  static void reset() => launchedThisVisit = false;
}
