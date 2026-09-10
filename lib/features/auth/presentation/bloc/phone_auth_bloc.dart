import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/analytics/auth_event_properties.dart';
import 'package:app_template/core/analytics/onboarding_analytics.dart';
import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';
import 'package:app_template/features/auth/domain/truecaller_oauth_client.dart';
import 'package:app_template/features/auth/domain/usecases/auth_usecases.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_event.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_state.dart';

class PhoneAuthBloc extends Bloc<PhoneAuthEvent, PhoneAuthState> {
  PhoneAuthBloc({
    required SendPhoneOtpUseCase sendPhoneOtp,
    required VerifyPhoneOtpUseCase verifyPhoneOtp,
    required VerifyTruecallerLoginUseCase verifyTruecaller,
    required TruecallerOAuthClient truecallerOAuth,
    required AnalyticsService analytics,
  }) : _sendPhoneOtp = sendPhoneOtp,
       _verifyPhoneOtp = verifyPhoneOtp,
       _verifyTruecaller = verifyTruecaller,
       _truecallerOAuth = truecallerOAuth,
       _analytics = analytics,
       super(const PhoneAuthState()) {
    on<PhoneAuthOtpRequested>(_onOtpRequested);
    on<PhoneAuthOtpResent>(_onOtpResent);
    on<PhoneAuthOtpVerified>(_onOtpVerified);
    on<PhoneAuthTruecallerRequested>(_onTruecallerRequested);
    on<PhoneAuthReset>(_onReset);
  }

  final SendPhoneOtpUseCase _sendPhoneOtp;
  final VerifyPhoneOtpUseCase _verifyPhoneOtp;
  final VerifyTruecallerLoginUseCase _verifyTruecaller;
  final TruecallerOAuthClient _truecallerOAuth;
  final AnalyticsService _analytics;

  Future<void> _onOtpRequested(
    PhoneAuthOtpRequested event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final normalizedPhone = _normalizeIndianPhone(event.phone);
    final result = await _sendPhoneOtp(SendPhoneOtpParams(normalizedPhone));

    result.fold(
      (failure) {
        _analytics.logEvent(
          AnalyticsEvents.otpFailed,
          parameters: AuthEventProperties.otp(
            phoneNumber: normalizedPhone,
            extra: {
              AnalyticsProperties.step: AnalyticsValues.otpRequest,
              AnalyticsProperties.reason: failure.message,
              AnalyticsProperties.errorCode: failure.runtimeType.toString(),
            },
          ),
        );
        emit(state.copyWith(isLoading: false, error: failure));
      },
      (verificationId) {
        final props = AuthEventProperties.otp(phoneNumber: normalizedPhone);
        _analytics.logEvent(AnalyticsEvents.otpRequested, parameters: props);
        _analytics.logEvent(
          AnalyticsEvents.loginNumberAdded,
          parameters: props,
        );
        _analytics.logEvent(AnalyticsEvents.otpScreen, parameters: props);
        emit(
          state.copyWith(
            isLoading: false,
            clearError: true,
            step: PhoneAuthStep.otp,
            phoneNumber: normalizedPhone,
            verificationId: verificationId,
          ),
        );
      },
    );
  }

  Future<void> _onOtpResent(
    PhoneAuthOtpResent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    _analytics.logEvent(
      AnalyticsEvents.otpResend,
      parameters: AuthEventProperties.otp(
        phoneNumber: _normalizeIndianPhone(event.phone),
      ),
    );
    await _onOtpRequested(PhoneAuthOtpRequested(event.phone), emit);
  }

  Future<void> _onOtpVerified(
    PhoneAuthOtpVerified event,
    Emitter<PhoneAuthState> emit,
  ) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      emit(
        state.copyWith(
          isLoading: false,
          error: const AuthFailure('Verification expired. Request a new OTP.'),
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _verifyPhoneOtp(
      VerifyPhoneOtpParams(
        verificationId: verificationId,
        smsCode: event.otp.trim(),
      ),
    );

    result.fold((failure) {
      _analytics.logEvent(
        AnalyticsEvents.otpFailed,
        parameters: AuthEventProperties.otp(
          phoneNumber: state.phoneNumber,
          extra: {
            AnalyticsProperties.step: AnalyticsValues.otpVerify,
            AnalyticsProperties.reason: failure.message,
            AnalyticsProperties.errorCode: failure.runtimeType.toString(),
          },
        ),
      );
      emit(state.copyWith(isLoading: false, error: failure));
    }, (user) => _onVerifiedUser(user, emit));
  }

  Future<void> _onTruecallerRequested(
    PhoneAuthTruecallerRequested event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    TruecallerAuthorization authorization;
    try {
      authorization = await _truecallerOAuth.authorize(
        onConsentScreenRequested: () {
          unawaited(_analytics.logEvent(AnalyticsEvents.truecallerInitiated));
        },
      );
    } on AuthException catch (error) {
      if (isClosed) return;
      if (!_shouldSilenceTruecallerFailure(error.message)) {
        unawaited(
          _analytics.logEvent(
            AnalyticsEvents.truecallerFailed,
            parameters: {AnalyticsProperties.reason: error.message},
          ),
        );
        emit(
          state.copyWith(isLoading: false, error: AuthFailure(error.message)),
        );
        return;
      }
      emit(state.copyWith(isLoading: false, clearError: true));
      return;
    } catch (error) {
      if (isClosed) return;
      unawaited(
        _analytics.logEvent(
          AnalyticsEvents.truecallerFailed,
          parameters: {AnalyticsProperties.reason: error.toString()},
        ),
      );
      emit(
        state.copyWith(
          isLoading: false,
          error: const AuthFailure(
            'Truecaller verification failed. Please try OTP.',
          ),
        ),
      );
      return;
    }

    if (isClosed) return;
    unawaited(_analytics.logEvent(AnalyticsEvents.truecallerProceed));
    final result = await _verifyTruecaller(
      VerifyTruecallerLoginParams(
        authorizationCode: authorization.authorizationCode,
        codeVerifier: authorization.codeVerifier,
      ),
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        _analytics.logEvent(
          AnalyticsEvents.truecallerFailed,
          parameters: {
            AnalyticsProperties.reason: failure.message,
            AnalyticsProperties.errorCode: failure.runtimeType.toString(),
          },
        );
        emit(state.copyWith(isLoading: false, error: failure));
      },
      (user) {
        _onVerifiedUser(
          user,
          emit,
          loginType: AnalyticsValues.loginTypeTruecaller,
        );
      },
    );
  }

  void _onVerifiedUser(
    User user,
    Emitter<PhoneAuthState> emit, {
    String loginType = AnalyticsValues.loginTypeOtp,
  }) {
    _analytics.setUserId(user.id);
    _analytics.logEvent(
      AnalyticsEvents.otpVerified,
      parameters: AuthEventProperties.forLoginType(
        loginType: loginType,
        phoneNumber: user.phone,
      ),
    );
    _applyIdentityToProfile(_analytics, user);
    unawaited(
      logOnboardingCompletedOnce(
        analytics: _analytics,
        loginType: loginType,
        phoneNumber: user.phone,
      ),
    );
    _analytics.setUserProfileProperty(
      AnalyticsUserProperties.signUpDate,
      DateTime.now().toIso8601String(),
    );
    emit(state.copyWith(isLoading: false, clearError: true));
  }

  void _onReset(PhoneAuthReset event, Emitter<PhoneAuthState> emit) {
    _truecallerOAuth.cancel();
    emit(const PhoneAuthState());
  }

  @override
  Future<void> close() {
    _truecallerOAuth.cancel();
    return super.close();
  }

  bool _shouldSilenceTruecallerFailure(String message) {
    final lower = message.toLowerCase();
    return lower.contains('not available') ||
        lower.contains('not supported') ||
        lower.contains('cancelled') ||
        lower.contains('canceled');
  }

  String _normalizeIndianPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.length == 10) {
      return '+91$digits';
    }
    if (phone.startsWith('+')) {
      return phone;
    }
    return '+$digits';
  }
}

void _applyIdentityToProfile(AnalyticsService analytics, User user) {
  final number = AuthEventProperties.fullNumber(user.phone);
  if (number.isNotEmpty) {
    analytics.setUserProfileProperty(AnalyticsUserProperties.phone, user.phone);
    analytics.setSuperProperty(AnalyticsSuperProperties.number, number);
  }
  final email = user.email;
  if (email != null && email.isNotEmpty) {
    analytics.setUserProfileProperty(AnalyticsUserProperties.email, email);
  }
  final name = user.displayName;
  if (name != null && name.isNotEmpty) {
    analytics.setUserProfileProperty(AnalyticsUserProperties.name, name);
  }
}
