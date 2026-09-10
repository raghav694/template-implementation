import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/auth/domain/usecases/auth_usecases.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_truecaller_oauth_client.dart';
import 'fakes/recording_analytics_service.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeTruecallerOAuthClient oauth;
  late RecordingAnalyticsService analytics;
  late PhoneAuthBloc bloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthRepository();
    oauth = FakeTruecallerOAuthClient();
    analytics = RecordingAnalyticsService();
    bloc = PhoneAuthBloc(
      sendPhoneOtp: SendPhoneOtpUseCase(auth),
      verifyPhoneOtp: VerifyPhoneOtpUseCase(auth),
      verifyTruecaller: VerifyTruecallerLoginUseCase(auth),
      truecallerOAuth: oauth,
      analytics: analytics,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  test('Truecaller success persists a session like OTP verify', () async {
    final done = bloc.stream.firstWhere(
      (state) => !state.isLoading && oauth.authorizeCalls > 0,
    );
    bloc.add(const PhoneAuthTruecallerRequested());
    await done;

    expect(auth.truecallerCalls, 1);
    expect(oauth.authorizeCalls, 1);
    expect(bloc.state.error, isNull);
    expect(auth.user?.id, 'fake-user');
    expect(
      analytics.logged.map((e) => e.name),
      containsAll(['truecallerInitiated', 'truecallerProceed', 'otpVerified']),
    );
    final verified = analytics.logged.firstWhere(
      (event) => event.name == AnalyticsEvents.otpVerified,
    );
    expect(verified.parameters?[AnalyticsProperties.number], '919876543210');
    expect(
      verified.parameters?[AnalyticsProperties.loginType],
      AnalyticsValues.loginTypeTruecaller,
    );
  });

  test('Truecaller SDK unavailability stays on OTP with no error banner', () async {
    oauth.error = const AuthException(
      'Truecaller is not available on this device.',
    );

    final done = bloc.stream.firstWhere(
      (state) => !state.isLoading && oauth.authorizeCalls > 0,
    );
    bloc.add(const PhoneAuthTruecallerRequested());
    await done;

    expect(auth.truecallerCalls, 0);
    expect(bloc.state.error, isNull);
    expect(
      analytics.logged.map((e) => e.name),
      isNot(contains('truecallerFailed')),
    );
  });

  test('Truecaller backend failure surfaces on the phone step', () async {
    auth.truecallerFailure = const ServerFailure('Truecaller login failed');

    final done = bloc.stream.firstWhere(
      (state) => !state.isLoading && state.error != null,
    );
    bloc.add(const PhoneAuthTruecallerRequested());
    await done;

    expect(auth.truecallerCalls, 1);
    expect(bloc.state.error, isA<ServerFailure>());
  });
}
