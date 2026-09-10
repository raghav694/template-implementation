import 'package:flutter/material.dart';

import 'package:app_template/config/app_identity.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';

/// Blocking screen while the backend reports the app is under maintenance.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({this.title, this.message, super.key});

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final name = AppIdentity.appName.startsWith('__')
        ? 'App'
        : AppIdentity.appName;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.primaryDim,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title?.trim().isNotEmpty == true
                      ? title!.trim()
                      : '$name is temporarily unavailable',
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message?.trim().isNotEmpty == true
                      ? message!.trim()
                      : 'We are performing maintenance. Please try again shortly.',
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
