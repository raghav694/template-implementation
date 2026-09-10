import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/attribution/play_install_referrer_parser.dart';
import 'package:app_template/core/attribution/utm_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists UTM source/medium and the onboarding deeplink.
///
/// Live deeplinks overwrite source/medium (same as the frontend
/// `EventsService.saveUtmData`). Mixpanel still uses set-once at login so the
/// first acquisition values win on the profile.
class AttributionStore {
  AttributionStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const utmSourceKey = 'attribution_utm_source';
  static const utmMediumKey = 'attribution_utm_medium';
  static const refKey = 'attribution_utm_ref';
  static const gclidKey = 'attribution_gclid';
  static const gbraidKey = 'attribution_gbraid';
  static const onboardingDeeplinkKey = 'attribution_onboarding_deeplink';
  static const playReferrerConsumedKey = 'attribution_play_referrer_consumed';

  final SharedPreferences? _prefsOverride;
  UtmData _data = const UtmData();

  UtmData get data => _data;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<void> hydrate() async {
    final prefs = await _prefs;
    _data = UtmData(
      utmSource: prefs.getString(utmSourceKey),
      utmMedium: prefs.getString(utmMediumKey),
      ref: prefs.getString(refKey),
      gclid: prefs.getString(gclidKey),
      gbraid: prefs.getString(gbraidKey),
      onboardingDeeplink: prefs.getString(onboardingDeeplinkKey),
    );
  }

  Future<void> saveFromUri(Uri deeplink) async {
    final params = deeplink.queryParameters;
    await _persist(
      utmSource: params['utm_source'] ?? params['utmSource'],
      utmMedium: params['utm_medium'] ?? params['utmMedium'],
      ref: params['ref'],
      gclid: params['gclid'],
      gbraid: params['gbraid'],
      onboardingDeeplink: deeplink.toString(),
    );
  }

  Future<void> saveFromReferrer(String referrer) async {
    final params = parseInstallReferrer(referrer);
    await saveFromReferrerParams(params);
  }

  Future<void> saveFromReferrerParams(Map<String, String> params) async {
    await _persist(
      utmSource: params['utm_source'] ?? params['utmSource'],
      utmMedium: params['utm_medium'] ?? params['utmMedium'],
      ref: params['ref'],
      gclid: params['gclid'],
      gbraid: params['gbraid'],
    );
  }

  Future<bool> consumePlayReferrer() async {
    final prefs = await _prefs;
    if (prefs.getBool(playReferrerConsumedKey) ?? false) return false;
    await prefs.setBool(playReferrerConsumedKey, true);
    return true;
  }

  Future<void> applyToAnalytics(AnalyticsService analytics) async {
    await hydrate();
    final utm = _data;
    if (!utm.hasData) return;
    if (utm.utmSource?.isNotEmpty ?? false) {
      await analytics.setUserProfilePropertyOnce(
        AnalyticsUserProperties.utmSource,
        utm.utmSource,
      );
    }
    if (utm.utmMedium?.isNotEmpty ?? false) {
      await analytics.setUserProfilePropertyOnce(
        AnalyticsUserProperties.utmMedium,
        utm.utmMedium,
      );
    }
    if (utm.onboardingDeeplink?.isNotEmpty ?? false) {
      await analytics.setUserProfilePropertyOnce(
        AnalyticsUserProperties.onboardingDeeplink,
        utm.onboardingDeeplink,
      );
    }
  }

  Future<void> _persist({
    String? utmSource,
    String? utmMedium,
    String? ref,
    String? gclid,
    String? gbraid,
    String? onboardingDeeplink,
  }) async {
    final prefs = await _prefs;
    if (utmSource != null && utmSource.isNotEmpty) {
      await prefs.setString(utmSourceKey, utmSource);
    }
    if (utmMedium != null && utmMedium.isNotEmpty) {
      await prefs.setString(utmMediumKey, utmMedium);
    }
    if (ref != null && ref.isNotEmpty) {
      await prefs.setString(refKey, ref);
    }
    if (gclid != null && gclid.isNotEmpty) {
      await prefs.setString(gclidKey, gclid);
    }
    if (gbraid != null && gbraid.isNotEmpty) {
      await prefs.setString(gbraidKey, gbraid);
    }
    if (onboardingDeeplink != null && onboardingDeeplink.isNotEmpty) {
      await prefs.setString(onboardingDeeplinkKey, onboardingDeeplink);
    }
    await hydrate();
  }
}
