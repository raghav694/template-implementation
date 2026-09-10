import 'package:app_template/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthDot extends StatelessWidget {
  const AuthDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
          color: AppColors.textDisabled,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
