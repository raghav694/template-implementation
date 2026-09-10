import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/paywall/presentation/widgets/upi_app_icon.dart';
import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';
import 'package:flutter/material.dart';

class UpiAppList extends StatelessWidget {
  const UpiAppList({
    super.key,
    required this.upiApps,
    required this.selectedPackageName,
    required this.onAppSelected,
    required this.onBack,
  });

  final List<UpiAppInfo> upiApps;
  final String? selectedPackageName;
  final ValueChanged<UpiAppInfo> onAppSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Select UPI app', style: AppTypography.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: upiApps.length,
            itemBuilder: (context, index) {
              final app = upiApps[index];
              final isSelected = selectedPackageName == app.packageName;
              return GestureDetector(
                onTap: () => onAppSelected(app),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: AppSpacing.lg),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 42,
                        width: 42,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                          child: UpiAppIcon(app: app, size: 42),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        app.appName,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
