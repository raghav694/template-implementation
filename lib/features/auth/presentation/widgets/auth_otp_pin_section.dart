import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_otp_sent_to_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

/// 6-digit OTP pin input using [Pinput], styled to match the light-theme
/// accent palette.
class AuthOtpPinSection extends StatelessWidget {
  const AuthOtpPinSection({
    super.key,
    required this.phoneNo,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.readOnly = false,
    this.smsRetriever,
  });

  final String phoneNo;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final bool readOnly;

  /// Optional auto-fill source — see [OtpSmsRetriever]. `null` just means
  /// manual entry only, no auto-fill attempted.
  final SmsRetriever? smsRetriever;

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: AppTypography.textTheme.headlineMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    final submittedTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthOtpSentToText(phoneNo: phoneNo),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: IgnorePointer(
            ignoring: readOnly,
            child: Pinput(
              length: 6,
              controller: controller,
              focusNode: focusNode,
              autofocus: !readOnly,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              defaultPinTheme: defaultTheme,
              focusedPinTheme: focusedTheme,
              submittedPinTheme: submittedTheme,
              separatorBuilder: (_) => const SizedBox(width: 8),
              cursor: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: VerticalDivider(thickness: 2, color: AppColors.primary),
              ),
              onChanged: onChanged,
              smsRetriever: smsRetriever,
            ),
          ),
        ),
      ],
    );
  }
}
