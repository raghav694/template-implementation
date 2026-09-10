import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/paywall/presentation/widgets/upi_app_icon.dart';
import 'package:app_template/features/paywall/presentation/widgets/upi_app_list.dart';
import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';
import 'package:flutter/material.dart';

class UpiAppSelector extends StatefulWidget {
  const UpiAppSelector({
    super.key,
    required this.upiApps,
    required this.selectedApp,
    required this.onAppSelected,
  });

  final List<UpiAppInfo> upiApps;
  final UpiAppInfo? selectedApp;
  final ValueChanged<UpiAppInfo> onAppSelected;

  @override
  State<UpiAppSelector> createState() => _UpiAppSelectorState();
}

class _UpiAppSelectorState extends State<UpiAppSelector> {
  var _isListExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.upiApps.isEmpty) return const SizedBox.shrink();

    if (_isListExpanded) {
      return UpiAppList(
        upiApps: widget.upiApps,
        selectedPackageName: widget.selectedApp?.packageName,
        onAppSelected: (app) {
          widget.onAppSelected(app);
          setState(() => _isListExpanded = false);
        },
        onBack: () => setState(() => _isListExpanded = false),
      );
    }

    final selected = widget.selectedApp;
    if (selected == null) return const SizedBox.shrink();

    return Row(
      children: [
        SizedBox(
          height: 32,
          width: 32,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: UpiAppIcon(app: selected, size: 32),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            selected.appName,
            style: AppTypography.textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _isListExpanded = true),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
