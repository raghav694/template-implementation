import 'package:app_template/core/deeplink/incoming_deeplink.dart';
import 'package:app_template/core/deeplink/offer_type.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_checkout_cubit.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_plan_cubit.dart';
import 'package:app_template/features/paywall/presentation/screens/paywall_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Generic paywall: shows the single plan resolved from a deeplink plan id
/// or, if none, Remote Config + Capslock Payments catalog. Checkout UI is
/// host-owned PaywallCheckout; Capslock supplies initiate, UPI, and status.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({
    this.deeplinkPlanId,
    this.offerType,
    this.source,
    super.key,
  });

  factory PaywallScreen.fromRoute(GoRouterState state) {
    final source = state.uri.queryParameters['source']?.trim();
    final pathPlanId = state.pathParameters['planId']?.trim();
    return PaywallScreen(
      deeplinkPlanId:
          IncomingDeeplink.planIdFrom(state.uri) ??
          (pathPlanId == null || pathPlanId.isEmpty ? null : pathPlanId),
      offerType: IncomingDeeplink.offerTypeFrom(state.uri),
      source: (source == null || source.isEmpty) ? null : source,
    );
  }

  final String? deeplinkPlanId;
  final OfferType? offerType;
  final String? source;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<PaywallPlanCubit>()),
        BlocProvider.value(value: getIt<PaywallCheckoutCubit>()),
      ],
      child: PaywallView(
        deeplinkPlanId: deeplinkPlanId,
        offerType: offerType,
        source: source,
      ),
    );
  }
}
