import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/theme/app_colors.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const AppLogo(size: 32, showName: true),
          const Spacer(),
          Material(
            color: AppColors.primarySoft,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Profile',
              onPressed: () => context.push(RoutePaths.profile),
              icon: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primaryDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
