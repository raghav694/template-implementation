import 'dart:async';

import 'package:truecaller_sdk/truecaller_sdk.dart';

import 'package:app_template/config/app_identity.dart';
import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/features/auth/domain/truecaller_oauth_client.dart';

/// Wraps `truecaller_sdk` OAuth PKCE (Vokey / Voice Club flow, BLoC-shaped).
class TruecallerOAuthClientImpl implements TruecallerOAuthClient {
  StreamSubscription<TcSdkCallback>? _subscription;
  Completer<TruecallerAuthorization>? _completer;

  static String get oauthState {
    final package = AppIdentity.androidPackage.trim();
    if (package.isNotEmpty && !package.startsWith('__')) return package;
    final host = AppIdentity.deeplinkHost.trim();
    if (host.isNotEmpty && !host.startsWith('__')) return host;
    return 'app.truecaller';
  }

  @override
  Future<TruecallerAuthorization> authorize({
    void Function()? onConsentScreenRequested,
  }) async {
    cancel();
    final completer = Completer<TruecallerAuthorization>();
    _completer = completer;

    try {
      TcSdk.initializeSDK(sdkOption: TcSdkOptions.OPTION_VERIFY_ONLY_TC_USERS);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final isUsable = await TcSdk.isOAuthFlowUsable;
      if (isUsable != true) {
        throw const AuthException(
          'Truecaller is not available on this device.',
        );
      }

      final state = oauthState;
      await TcSdk.setOAuthState(state);
      await TcSdk.setOAuthScopes(['profile', 'phone', 'openid']);

      final verifierRaw = await TcSdk.generateRandomCodeVerifier;
      final codeVerifier = verifierRaw?.toString() ?? '';
      if (codeVerifier.isEmpty || codeVerifier == 'null') {
        throw const AuthException('Truecaller could not start. Try OTP.');
      }

      final challengeRaw = await TcSdk.generateCodeChallenge(codeVerifier);
      final codeChallenge = challengeRaw?.toString() ?? '';
      if (codeChallenge.isEmpty || codeChallenge == 'null') {
        throw const AuthException(
          'Truecaller is not supported on this device.',
        );
      }
      await TcSdk.setCodeChallenge(codeChallenge);
      unawaited(TcSdk.getAuthorizationCode);
      onConsentScreenRequested?.call();

      _subscription = TcSdk.streamCallbackData.listen(
        (callback) => _handleCallback(callback, state, codeVerifier),
        onError: (Object error) {
          _fail(AuthException(error.toString()));
        },
      );

      return completer.future;
    } on AuthException {
      cancel();
      rethrow;
    } catch (error) {
      cancel();
      throw AuthException(error.toString());
    }
  }

  void _handleCallback(
    TcSdkCallback callback,
    String expectedState,
    String codeVerifier,
  ) {
    switch (callback.result) {
      case TcSdkCallbackResult.success:
        final data = callback.tcOAuthData;
        if (data == null) {
          _fail(const AuthException('Truecaller returned incomplete data.'));
          return;
        }
        if (data.state != expectedState) {
          _fail(const AuthException('Truecaller verification failed.'));
          return;
        }
        final authCode = data.authorizationCode;
        if (authCode.isEmpty) {
          _fail(const AuthException('Truecaller verification failed.'));
          return;
        }
        _succeed(
          TruecallerAuthorization(
            authorizationCode: authCode,
            codeVerifier: codeVerifier,
          ),
        );
      case TcSdkCallbackResult.verifiedBefore:
      case TcSdkCallbackResult.verification:
        return;
      case TcSdkCallbackResult.failure:
        final errorCode = callback.error?.code ?? 0;
        final message = callback.error?.message?.trim();
        _fail(
          AuthException(
            (message != null && message.isNotEmpty)
                ? 'ErrorCode: $errorCode Reason: $message'
                : 'Truecaller verification failed.',
          ),
        );
      default:
        _fail(const AuthException('Truecaller verification failed.'));
    }
  }

  void _succeed(TruecallerAuthorization authorization) {
    final completer = _completer;
    if (completer == null || completer.isCompleted) return;
    completer.complete(authorization);
  }

  void _fail(AuthException error) {
    final completer = _completer;
    if (completer == null || completer.isCompleted) return;
    completer.completeError(error);
  }

  @override
  void cancel() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        const AuthException('Truecaller verification cancelled.'),
      );
    }
    _completer = null;
  }
}
