import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/features/auth/domain/truecaller_oauth_client.dart';

class FakeTruecallerOAuthClient implements TruecallerOAuthClient {
  FakeTruecallerOAuthClient({this.authorization, this.error});

  TruecallerAuthorization? authorization;
  Object? error;
  var authorizeCalls = 0;
  var cancelCalls = 0;

  @override
  Future<TruecallerAuthorization> authorize({
    void Function()? onConsentScreenRequested,
  }) async {
    authorizeCalls += 1;
    final thrown = error;
    if (thrown != null) {
      if (thrown is Exception) throw thrown;
      throw AuthException(thrown.toString());
    }
    onConsentScreenRequested?.call();
    return authorization ??
        const TruecallerAuthorization(
          authorizationCode: 'auth-code',
          codeVerifier: 'code-verifier',
        );
  }

  @override
  void cancel() {
    cancelCalls += 1;
  }
}
