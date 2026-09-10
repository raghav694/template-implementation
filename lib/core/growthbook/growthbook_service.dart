import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:growthbook_sdk_flutter/growthbook_sdk_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/attribution/utm_data.dart';
import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/growthbook/growthbook_keys.dart';

/// Thin wrapper around [GrowthBookSDK]. Register as a GetIt singleton.
///
/// Call [initialize] once at startup. Every read after that is safe: a missing
/// key, a failed fetch, an unset `GROWTHBOOK_API_KEY`, or a fetch still in
/// flight all resolve to the caller's default rather than throwing. Startup is
/// never blocked for longer than [_initTimeout] — the SDK caches features on
/// disk, so a slow first launch serves defaults and picks up values next time.
class GrowthBookService {
  static const _anonymousIdKey = 'app_growthbook_anonymous_id';
  static const _initTimeout = Duration(seconds: 6);

  GrowthBookSDK? _sdk;
  var _initStarted = false;
  String? _anonymousId;
  Map<String, dynamic> _attributes = const {};

  /// True once features have been fetched (or restored from cache).
  bool get isReady => _sdk != null;

  /// Stable per-install id used as the GrowthBook bucketing attribute, so
  /// pre-login experiments keep the same assignment after the user logs in.
  String? get anonymousId => _anonymousId;

  @visibleForTesting
  Map<String, dynamic> get debugAttributes =>
      Map<String, dynamic>.of(_attributes);

  Future<void> initialize() async {
    if (_initStarted) return;
    _initStarted = true;

    final configured = _hasConfig;
    if (!configured) {
      debugPrint('GrowthBook disabled: GROWTHBOOK_API_KEY is not set');
      return;
    }

    _anonymousId = await _loadOrCreateAnonymousId();
    final base = await _baseAttributes();
    _attributes = {...base, ..._attributes};

    await _build().timeout(
      _initTimeout,
      onTimeout: () => debugPrint(
        'GrowthBook fetch slow — serving defaults for this launch',
      ),
    );
  }

  bool get _hasConfig {
    try {
      return AppConfig.hasGrowthBookConfig;
    } catch (_) {
      return false;
    }
  }

  /// Initializes GrowthBook once if it has not started yet.
  Future<void> initializeIfNeeded() => initialize();

  /// Applies targeting attributes, then ensures features are evaluated with
  /// that context — call before reading paywall plan assignments.
  Future<void> prepareForPlanEvaluation({
    String? languageCode,
    String? userId,
    bool? isPremium,
  }) async {
    updateAttributes({
      if (languageCode != null && languageCode.isNotEmpty)
        GrowthBookAttributes.languageCode: languageCode,
      if (userId != null && userId.isNotEmpty)
        GrowthBookAttributes.userId: userId,
      GrowthBookAttributes.isPremium: ?isPremium,
    });

    if (!_initStarted) {
      await initialize();
      logDebugState(context: 'prepareForPlanEvaluation');
      return;
    }

    final sdk = _sdk;
    if (sdk == null) {
      logDebugState(context: 'prepareForPlanEvaluation (sdk null)');
      return;
    }

    try {
      await sdk.setAttributesAsync(Map<String, dynamic>.of(_attributes));
      logDebugState(context: 'prepareForPlanEvaluation');
    } catch (error) {
      debugPrint('GrowthBook prepareForPlanEvaluation failed: $error');
    }
  }

  Future<void> _build() async {
    try {
      final sdk = await GBSDKBuilderApp(
        hostURL: AppConfig.growthBookHostUrl,
        apiKey: AppConfig.growthBookApiKey,
        attributes: _attributes,
        backgroundSync: true,
        growthBookTrackingCallBack: (_) {},
        onInitializationFailure: (error) =>
            debugPrint('GrowthBook initialization failed: ${error?.error}'),
      ).initialize();

      _sdk = sdk;
      sdk.setAttributes(_attributes);
      logDebugState(context: 'initialize');
    } catch (error, stackTrace) {
      debugPrint('GrowthBookService initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Merges [values] into the targeting attributes and pushes them to the SDK.
  ///
  /// Safe to call before [initialize] finishes — the values are held and
  /// applied as soon as the SDK lands.
  void updateAttributes(Map<String, dynamic> values) {
    if (values.isEmpty) return;
    final merged = Map<String, dynamic>.of(_attributes);
    for (final entry in values.entries) {
      if (entry.value == null) continue;
      merged[entry.key] = entry.value;
    }
    if (mapEquals(merged, _attributes)) return;
    _attributes = merged;

    try {
      _sdk?.setAttributes(_attributes);
    } catch (error) {
      debugPrint('GrowthBook setAttributes failed: $error');
    }
  }

  /// Identifies the signed-in user. Keeps `id` on the anonymous id so a user's
  /// bucket does not shift the moment they log in.
  void setUser({String? userId, bool? isPremium}) {
    updateAttributes({
      if (userId != null && userId.isNotEmpty)
        GrowthBookAttributes.userId: userId,
      GrowthBookAttributes.isPremium: ?isPremium,
    });
  }

  /// Campaign / install params used for targeting. Mixpanel still gets
  /// set-once UTM separately.
  void applyAttribution(UtmData utm) {
    updateAttributes({
      if (utm.utmSource?.isNotEmpty ?? false)
        GrowthBookAttributes.utmSource: utm.utmSource,
      if (utm.utmMedium?.isNotEmpty ?? false)
        GrowthBookAttributes.utmMedium: utm.utmMedium,
      if (utm.ref?.isNotEmpty ?? false) GrowthBookAttributes.ref: utm.ref,
      if (utm.gclid?.isNotEmpty ?? false) GrowthBookAttributes.gclid: utm.gclid,
      if (utm.gbraid?.isNotEmpty ?? false)
        GrowthBookAttributes.gbraid: utm.gbraid,
    });
  }

  Future<Map<String, dynamic>> _baseAttributes() async {
    var appVersion = '';
    try {
      appVersion = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    final languageCode = PlatformDispatcher.instance.locale.languageCode;
    return <String, dynamic>{
      GrowthBookAttributes.id: _anonymousId ?? '',
      GrowthBookAttributes.anonymousId: _anonymousId ?? '',
      GrowthBookAttributes.platform: defaultTargetPlatform.name,
      if (appVersion.isNotEmpty) GrowthBookAttributes.appVersion: appVersion,
      if (languageCode.isNotEmpty)
        GrowthBookAttributes.languageCode: languageCode,
    };
  }

  Future<String> _loadOrCreateAnonymousId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_anonymousIdKey);
      if (existing != null && existing.isNotEmpty) return existing;

      final random = Random();
      final generated =
          'anon_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
          '_${random.nextInt(1 << 32).toRadixString(36)}';
      await prefs.setString(_anonymousIdKey, generated);
      return generated;
    } catch (error) {
      debugPrint('GrowthBook anonymous id unavailable: $error');
      return '';
    }
  }

  bool isOn(String key, {bool defaultValue = false}) {
    final result = _feature(key);
    if (result == null) return defaultValue;
    return result.on;
  }

  String getString(String key, {String defaultValue = ''}) {
    final value = _feature(key)?.value;
    if (value == null) return defaultValue;
    final text = value is String ? value : value.toString();
    return text.trim().isNotEmpty ? text.trim() : defaultValue;
  }

  /// Whether Play Store force-update should run on launch / resume.
  ///
  /// Accepts both a pure on/off flag and a boolean-valued feature.
  bool isForceUpdate() {
    final result = _feature(GrowthBookKeys.forceUpdate);
    if (result == null) return false;
    if (result.value == true) return true;
    return result.on;
  }

  /// Assigned paywall plan id when the feature is on. Empty means fall through
  /// to Remote Config.
  String conversionPlanId() {
    if (!isOn(GrowthBookKeys.conversionPlanId)) return '';
    return getString(GrowthBookKeys.conversionPlanId);
  }

  /// Every known key that is currently on, with its value.
  Map<String, dynamic> enabledFeatures() {
    final enabled = <String, dynamic>{};
    for (final key in GrowthBookKeys.known) {
      final result = _feature(key);
      if (result == null || !result.on) continue;
      enabled[key] = result.value;
    }
    return enabled;
  }

  /// Debug-only snapshot of attributes and known feature evaluations.
  void logDebugState({String? context}) {
    if (!kDebugMode) return;

    final label = context == null ? 'GrowthBook' : 'GrowthBook ($context)';
    debugPrint('── $label ── ready=$isReady');

    if (_attributes.isEmpty) {
      debugPrint('  attributes: {}');
    } else {
      debugPrint('  attributes: ${jsonEncode(_attributes)}');
    }

    for (final key in GrowthBookKeys.known) {
      final result = _feature(key);
      if (result == null) {
        debugPrint('  $key: <unavailable>');
        continue;
      }
      debugPrint(
        '  $key: on=${result.on} value=${result.value} '
        'source=${result.source?.name ?? 'null'} '
        'experiment=${result.experimentResult?.inExperiment == true}',
      );
    }

    debugPrint('── end $label ──');
  }

  GBFeatureResult? _feature(String key) {
    final sdk = _sdk;
    if (sdk == null) return null;
    try {
      final result = sdk.feature(key);
      if (result.source == GBFeatureSource.unknownFeature) return null;
      return result;
    } catch (error) {
      debugPrint('GrowthBook read failed for "$key": $error');
      return null;
    }
  }
}
