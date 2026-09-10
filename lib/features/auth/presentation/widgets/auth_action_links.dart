import 'package:app_template/features/auth/presentation/widgets/auth_dot.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_link_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthActionLinks extends StatelessWidget {
  const AuthActionLinks({
    super.key,
    required this.onResend,
    required this.onChangePhone,
  });

  final VoidCallback onResend;
  final VoidCallback onChangePhone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthLinkButton(
            label: 'Resend code',
            onTap: () {
              HapticFeedback.selectionClick();
              onResend();
            },
          ),
          const AuthDot(),
          AuthLinkButton(
            label: 'Change number',
            onTap: () {
              HapticFeedback.selectionClick();
              onChangePhone();
            },
          ),
        ],
      ),
    );
  }
}
