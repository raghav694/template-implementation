import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/analytics/auth_event_properties.dart';
import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/features/auth/presentation/bloc/login_screen_analytics_guard.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_event.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_state.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_form_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _phoneFilled = false;
  bool _otpFilled = false;
  var _loginScreenLogged = false;

  @override
  void initState() {
    super.initState();
    // Single source of truth for `_phoneFilled`: fires for every input path
    // (typing, paste, autofill framework, programmatic controller writes)
    // unlike onChanged which is skipped for programmatic assignments.
    _phoneController.addListener(_onPhoneChanged);
    if (_shouldAutoLaunchTruecaller &&
        !TruecallerAutoLaunchGuard.launchedThisVisit) {
      TruecallerAutoLaunchGuard.launchedThisVisit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _continueWithTruecaller();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // See LoginScreenAnalyticsGuard: go_router can remount this screen more
    // than once per cold start, and without this loginScreen fired twice.
    if (_loginScreenLogged) return;
    _loginScreenLogged = true;
    if (!LoginScreenAnalyticsGuard.loggedThisVisit) {
      LoginScreenAnalyticsGuard.loggedThisVisit = true;
      getIt<AnalyticsService>().logEvent(
        AnalyticsEvents.loginScreen,
        parameters: AuthEventProperties.otp(),
      );
    }
  }

  /// Called whenever the phone controller value changes — covers every input
  /// path: manual typing, paste, autofill framework, and programmatic writes.
  void _onPhoneChanged() {
    if (!mounted) return;
    final isValid =
        IndianPhoneInputFormatter.normalize(_phoneController.text) != null;
    if (_phoneFilled != isValid) {
      setState(() => _phoneFilled = isValid);
    }
    if (isValid) {
      // Tell the OS the autofill form is complete so it can store the value.
      TextInput.finishAutofillContext();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    // Re-validate at submission time: the `_phoneFilled` flag and controller
    // text can diverge if the autofill framework or OEM keyboard writes to the
    // controller after `_phoneFilled` was set. This is the last line of
    // defence before the network call — nothing unvalidated reaches the backend.
    final phone = IndianPhoneInputFormatter.normalize(_phoneController.text);
    if (phone == null) return;

    FocusScope.of(context).unfocus();
    context.read<PhoneAuthBloc>().add(
      PhoneAuthOtpRequested(_phoneController.text),
    );
  }

  void _continueWithTruecaller() {
    FocusScope.of(context).unfocus();
    context.read<PhoneAuthBloc>().add(const PhoneAuthTruecallerRequested());
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    context.read<PhoneAuthBloc>().add(
      PhoneAuthOtpVerified(_otpController.text),
    );
  }

  Future<void> _resendOtp() async {
    _otpController.clear();
    setState(() => _otpFilled = false);
    context.read<PhoneAuthBloc>().add(
      PhoneAuthOtpResent(_phoneController.text),
    );
  }

  void _changePhone() {
    context.read<PhoneAuthBloc>().add(const PhoneAuthReset());
    _otpController.clear();
    setState(() => _otpFilled = false);
  }

  String? _failureMessage(Object? error) {
    if (error is Failure) return error.message;
    return null;
  }

  static bool get _shouldAutoLaunchTruecaller {
    if (!AppConfig.hasTruecaller) return false;
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  static bool get _showTruecallerCta => _shouldAutoLaunchTruecaller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
      builder: (context, phoneAuthState) {
        final isLoading = phoneAuthState.isLoading;
        final errorMessage = _failureMessage(phoneAuthState.error);
        final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: AuthGradientBackground(
            child: SafeArea(
              maintainBottomViewPadding: true,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: phoneAuthState.step == PhoneAuthStep.phone
                    ? AuthPhoneView(
                        key: const ValueKey('phone'),
                        phoneController: _phoneController,
                        filled: _phoneFilled,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        keyboardVisible: keyboardVisible,
                        showTruecaller: _showTruecallerCta,
                        onSend: _sendOtp,
                        onTruecaller: _continueWithTruecaller,
                      )
                    : AuthOtpView(
                        key: const ValueKey('otp'),
                        otpController: _otpController,
                        phone: phoneAuthState.phoneNumber ?? '',
                        filled: _otpFilled,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        onOtpChanged: (v) {
                          setState(() => _otpFilled = v.length == 6);
                          if (v.length == 6 && !isLoading) _verifyOtp();
                        },
                        onVerify: _verifyOtp,
                        onResend: _resendOtp,
                        onChangePhone: _changePhone,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
