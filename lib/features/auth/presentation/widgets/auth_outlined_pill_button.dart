import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthOutlinedPillButton extends StatelessWidget {
  const AuthOutlinedPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isActive = enabled && !isLoading;
    return Opacity(
      opacity: isActive ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: isActive
            ? () {
                HapticFeedback.lightImpact();
                onTap?.call();
              }
            : null,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.primaryDim),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDim,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
        ),
      ),
    );
  }
}
