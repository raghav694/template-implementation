import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app_template/config/app_identity.dart';
import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/analytics/screen_view_once.dart';
import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/shared/widgets/app_soft_card.dart';
import 'package:app_template/shared/widgets/error_state_view.dart';
import 'package:app_template/shared/widgets/policy_webview_screen.dart';
import 'package:app_template/features/profile/presentation/widgets/profile_tile.dart';
import 'package:app_template/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:app_template/features/auth/presentation/bloc/sign_out_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final signOutState = context.watch<SignOutCubit>().state;

    return ScreenViewOnce(
      eventName: AnalyticsEvents.profileScreen,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: SafeArea(
          maintainBottomViewPadding: true,
          child: authState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorStateView.fromFailure(
              title: 'Could not load profile',
              failure: error is Failure
                  ? error
                  : UnknownFailure(error.toString()),
              onRetry: () => context.read<AuthCubit>().retry(),
            ),
            data: (user) {
              if (user == null) {
                return Center(
                  child: Text(
                    'Not signed in',
                    style: AppTypography.textTheme.bodyMedium,
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  AppSoftCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName?.isNotEmpty == true
                              ? user.displayName!
                              : AppIdentity.appName,
                          style: AppTypography.textTheme.titleLarge,
                        ),
                        if (user.phone.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            user.phone,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (user.email != null && user.email!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            user.email!,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppSoftCard(
                    child: Column(
                      children: [
                        ProfileTile(
                          icon: Icons.workspace_premium_outlined,
                          label: 'Plans',
                          onTap: () => context.push(RoutePaths.paywall),
                        ),
                        ProfileTile(
                          icon: Icons.payments_outlined,
                          label: 'Payment settings',
                          onTap: () => context.push(RoutePaths.paymentSettings),
                        ),
                        ProfileTile(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: () {
                            getIt<AnalyticsService>().logEvent(
                              AnalyticsEvents.privacyPolicyScreen,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PolicyWebViewScreen(
                                  title: 'Privacy Policy',
                                  url: AppIdentity.privacyUrl,
                                ),
                              ),
                            );
                          },
                        ),
                        ProfileTile(
                          icon: Icons.description_outlined,
                          label: 'Terms of Service',
                          onTap: () {
                            getIt<AnalyticsService>().logEvent(
                              AnalyticsEvents.termsOfServiceScreen,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PolicyWebViewScreen(
                                  title: 'Terms of Service',
                                  url: AppIdentity.termsUrl,
                                ),
                              ),
                            );
                          },
                        ),
                        ProfileTile(
                          icon: Icons.receipt_long_outlined,
                          label: 'Refund Policy',
                          onTap: () {
                            getIt<AnalyticsService>().logEvent(
                              AnalyticsEvents.refundPolicyScreen,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PolicyWebViewScreen(
                                  title: 'Refund Policy',
                                  url: AppIdentity.refundUrl,
                                ),
                              ),
                            );
                          },
                        ),
                        ProfileTile(
                          icon: Icons.mail_outline_rounded,
                          label: 'Help & Support',
                          onTap: () async {
                            getIt<AnalyticsService>().logEvent(
                              AnalyticsEvents.helpAndSupportScreen,
                            );
                            final uri = Uri(
                              scheme: 'mailto',
                              path: AppIdentity.supportEmail,
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: signOutState.isLoading
                        ? null
                        : () async {
                            HapticFeedback.lightImpact();
                            await context.read<SignOutCubit>().signOut();
                          },
                    child: signOutState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign out'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final info = snapshot.data;
                      if (info == null) return const SizedBox.shrink();
                      return Text(
                        '${info.appName} ${info.version} (${info.buildNumber})',
                        textAlign: TextAlign.center,
                        style: AppTypography.textTheme.labelSmall,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
