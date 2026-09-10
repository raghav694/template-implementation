/// Install / session attribution captured from deeplinks and Play Referrer.
class UtmData {
  const UtmData({
    this.utmSource,
    this.utmMedium,
    this.ref,
    this.gclid,
    this.gbraid,
    this.onboardingDeeplink,
  });

  final String? utmSource;
  final String? utmMedium;
  final String? ref;
  final String? gclid;
  final String? gbraid;
  final String? onboardingDeeplink;

  bool get hasData =>
      (utmSource?.isNotEmpty ?? false) ||
      (utmMedium?.isNotEmpty ?? false) ||
      (ref?.isNotEmpty ?? false) ||
      (gclid?.isNotEmpty ?? false) ||
      (gbraid?.isNotEmpty ?? false) ||
      (onboardingDeeplink?.isNotEmpty ?? false);
}
