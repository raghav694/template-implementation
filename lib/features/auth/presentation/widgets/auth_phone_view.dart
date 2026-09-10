import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_headline.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_outlined_pill_button.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_phone_input.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_pill_button.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_terms_text.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_top_bar.dart';
import 'package:app_template/features/auth/presentation/widgets/indian_phone_input_formatter.dart';
import 'package:flutter/material.dart';

class AuthPhoneView extends StatelessWidget {
  const AuthPhoneView({
    super.key,
    required this.phoneController,
    required this.filled,
    required this.isLoading,
    required this.errorMessage,
    required this.keyboardVisible,
    required this.showTruecaller,
    required this.onSend,
    required this.onTruecaller,
  });

  final TextEditingController phoneController;
  final bool filled;
  final bool isLoading;
  final String? errorMessage;
  final bool keyboardVisible;
  final bool showTruecaller;
  final VoidCallback onSend;
  final VoidCallback onTruecaller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthTopBar(),
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: keyboardVisible ? 24 : 80),
                const AuthHeadline(),
                SizedBox(height: keyboardVisible ? 28 : 48),
                AuthPhoneInput(
                  controller: phoneController,
                  inputFormatters: [IndianPhoneInputFormatter()],
                  readOnly: isLoading,
                ),
                const SizedBox(height: 16),
                const AuthTermsText(),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: errorMessage!),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            4,
            AppSpacing.xl,
            20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthPillButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                enabled: filled,
                isLoading: isLoading,
                onTap: onSend,
              ),
              if (showTruecaller) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                AuthOutlinedPillButton(
                  label: 'Continue with Truecaller',
                  enabled: !isLoading,
                  onTap: onTruecaller,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
