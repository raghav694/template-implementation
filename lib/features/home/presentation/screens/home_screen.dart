import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/screen_view_once.dart';
import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/home/presentation/widgets/home_app_bar.dart';
import 'package:app_template/shared/widgets/app_soft_card.dart';

/// Starter home shell. Replace this screen with app-specific product UI.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenViewOnce(
      eventName: AnalyticsEvents.landingPage,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          maintainBottomViewPadding: true,
          child: Column(
            children: [
              const HomeAppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  children: [
                    AppSoftCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome',
                            style: AppTypography.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'This is the reusable home shell. Add app-specific '
                            'features under lib/features/ and register them in '
                            'the router.',
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSoftCard(
                      onTap: () => context.push(RoutePaths.paywall),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plans',
                                  style: AppTypography.textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'See the paywall plan resolved from the '
                                  'plans API and Remote Config.',
                                  style: AppTypography.textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
