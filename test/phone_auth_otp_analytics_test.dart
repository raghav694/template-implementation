import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/auth/domain/usecases/auth_usecases.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_event.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_truecaller_oauth_client.dart';
import 'fakes/recording_analytics_service.dart';

void main() {
  late FakeAuthRepository auth;
  late RecordingAnalyticsService analytics;
  late PhoneAuthBloc bloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthRepository();
    analytics = RecordingAnalyticsService();
    bloc = PhoneAuthBloc(
      sendPhoneOtp: SendPhoneOtpUseCase(auth),
      verifyPhoneOtp: VerifyPhoneOtpUseCase(auth),
      verifyTruecaller: VerifyTruecallerLoginUseCase(auth),
      truecallerOAuth: FakeTruecallerOAuthClient(),
      analytics: analytics,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  Map<String, dynamic>? paramsFor(String name) {
    return analytics.logged
        .firstWhere((event) => event.name == name)
        .parameters;
  }

  test('OTP request events send full number and OTP loginType', () async {
    final done = bloc.stream.firstWhere(
      (state) => state.step == PhoneAuthStep.otp && !state.isLoading,
    );
    bloc.add(const PhoneAuthOtpRequested('9876543210'));
    await done;

    for (final name in [
      AnalyticsEvents.otpRequested,
      AnalyticsEvents.loginNumberAdded,
      AnalyticsEvents.otpScreen,
    ]) {
      expect(paramsFor(name)?[AnalyticsProperties.number], '919876543210');
      expect(
        paramsFor(name)?[AnalyticsProperties.loginType],
        AnalyticsValues.loginTypeOtp,
      );
    }
  });

  test('otpFailed on send includes number, loginType, and reason', () async {
    auth.sendOtpFailure = const ServerFailure('Could not send OTP');
    final done = bloc.stream.firstWhere(
      (state) => !state.isLoading && state.error != null,
    );
    bloc.add(const PhoneAuthOtpRequested('9876543210'));
    await done;

    final params = paramsFor(AnalyticsEvents.otpFailed);
    expect(params?[AnalyticsProperties.number], '919876543210');
    expect(
      params?[AnalyticsProperties.loginType],
      AnalyticsValues.loginTypeOtp,
    );
    expect(params?[AnalyticsProperties.reason], 'Could not send OTP');
  });

  test('otpVerified sends full number then onboardingCompleted once', () async {
    final otpReady = bloc.stream.firstWhere(
      (state) => state.step == PhoneAuthStep.otp && !state.isLoading,
    );
    bloc.add(const PhoneAuthOtpRequested('9876543210'));
    await otpReady;

    final verified = bloc.stream.firstWhere(
      (state) => !state.isLoading && state.error == null,
    );
    bloc.add(const PhoneAuthOtpVerified('1234'));
    await verified;
    await Future<void>.delayed(Duration.zero);

    final verifiedParams = paramsFor(AnalyticsEvents.otpVerified);
    expect(verifiedParams?[AnalyticsProperties.number], '919876543210');
    expect(
      verifiedParams?[AnalyticsProperties.loginType],
      AnalyticsValues.loginTypeOtp,
    );
    expect(
      analytics.logged.map((e) => e.name),
      contains(AnalyticsEvents.onboardingCompleted),
    );
  });
}
