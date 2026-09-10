abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});

  Future<void> setUserId(String userId);

  /// Sets a String-typed user profile property. Use [setUserProfileProperty]
  /// for non-String values (dates, numbers, booleans).
  Future<void> setUserProperty(String name, String value);

  /// Sets a user profile property with any value type.
  /// Mixpanel → people.set. Firebase → coerces to String via setUserProperty.
  Future<void> setUserProfileProperty(String name, dynamic value);

  /// Sets a user profile property only if it has never been set before.
  /// Mixpanel → people.setOnce (ideal for UTM / acquisition source).
  /// Firebase → setUserProperty (no once-semantics, always writes).
  /// Facebook → no-op.
  Future<void> setUserProfilePropertyOnce(String name, dynamic value);

  /// Increments a numeric user profile counter.
  /// Mixpanel → people.increment. Firebase → no-op (use event counts instead).
  Future<void> incrementUserProperty(String name, {double by = 1});

  /// Registers a super property sent with every subsequent event.
  /// Mixpanel → registerSuperProperties. Firebase → setUserProperty.
  Future<void> setSuperProperty(String name, dynamic value);

  Future<void> logScreenView(String screenName);

  /// Clears the current user identity. Must be called on logout.
  Future<void> reset();
}
