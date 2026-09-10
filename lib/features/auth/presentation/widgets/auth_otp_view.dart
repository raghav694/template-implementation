import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_action_links.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_otp_header.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_otp_pin_section.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_pill_button.dart';
import 'package:app_template/features/auth/presentation/widgets/otp_sms_retriever.dart';
import 'package:flutter/material.dart';

class AuthOtpView extends StatefulWidget {
  const AuthOtpView({
    super.key,
    required this.otpController,
    required this.phone,
    required this.filled,
    required this.isLoading,
    required this.errorMessage,
    required this.onOtpChanged,
    required this.onVerify,
    required this.onResend,
    required this.onChangePhone,
  });

  final TextEditingController otpController;
  final String phone;
  final bool filled;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onOtpChanged;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangePhone;

  @override
  State<AuthOtpView> createState() => _AuthOtpViewState();
}

class _AuthOtpViewState extends State<AuthOtpView> {
  final _focusNode = FocusNode();
  final _smsRetriever = OtpSmsRetriever();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _smsRetriever.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthOtpHeader(onBack: widget.onChangePhone),
        const SizedBox(height: 28),
        AuthOtpPinSection(
          phoneNo: widget.phone,
          controller: widget.otpController,
          onChanged: widget.onOtpChanged,
          focusNode: _focusNode,
          readOnly: widget.isLoading,
          smsRetriever: _smsRetriever,
        ),
        const SizedBox(height: 8),
        AuthActionLinks(
          onResend: widget.onResend,
          onChangePhone: widget.onChangePhone,
        ),
        if (widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              20,
              AppSpacing.xl,
              0,
            ),
            child: AuthErrorBanner(message: widget.errorMessage!),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            4,
            AppSpacing.xl,
            20,
          ),
          child: AuthPillButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            enabled: widget.filled,
            isLoading: widget.isLoading,
            onTap: widget.onVerify,
          ),
        ),
      ],
    );
  }
}
