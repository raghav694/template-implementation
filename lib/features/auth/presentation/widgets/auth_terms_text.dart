import 'package:app_template/config/app_identity.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/shared/widgets/policy_webview_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AuthTermsText extends StatelessWidget {
  const AuthTermsText({super.key});

  static String get _termsUrl => AppIdentity.termsUrl;
  static String get _privacyUrl => AppIdentity.privacyUrl;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      height: 1.5,
    );
    final linkStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: baseStyle,
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openPolicy(
                  context,
                  title: 'Terms of Service',
                  url: _termsUrl,
                ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openPolicy(
                  context,
                  title: 'Privacy Policy',
                  url: _privacyUrl,
                ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  void _openPolicy(
    BuildContext context, {
    required String title,
    required String url,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PolicyWebViewScreen(title: title, url: url),
      ),
    );
  }
}
