import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaywallHeader extends StatelessWidget {
  const PaywallHeader({required this.showClose, super.key});

  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          if (showClose)
            IconButton(
              tooltip: 'Close',
              onPressed: () => context.go(RoutePaths.home),
              icon: const Icon(Icons.close_rounded),
            )
          else
            const SizedBox(width: 48),
          const Expanded(
            child: Center(child: AppLogo(size: 28, showName: true)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
