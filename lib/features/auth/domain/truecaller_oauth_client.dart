class TruecallerAuthorization {
  const TruecallerAuthorization({
    required this.authorizationCode,
    required this.codeVerifier,
  });

  final String authorizationCode;
  final String codeVerifier;
}

/// Android Truecaller OAuth PKCE. Hosts must [cancel] when leaving login.
abstract class TruecallerOAuthClient {
  /// [onConsentScreenRequested] fires after the consent sheet is invoked —
  /// used for `truecallerInitiated`.
  Future<TruecallerAuthorization> authorize({
    void Function()? onConsentScreenRequested,
  });

  void cancel();
}
