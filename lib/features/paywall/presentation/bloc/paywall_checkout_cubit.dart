import 'package:capslock_payments_sdk/capslock_payments_sdk.dart' hide Plan;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/constants/paywall_sources.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/analytics/checkout_ids.dart';
import 'package:app_template/features/analytics/pending_events_service.dart';
import 'package:app_template/features/analytics/purchase_success_reporter.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';
import 'package:app_template/features/paywall/domain/services/payment_event_properties.dart';
import 'package:app_template/features/paywall/domain/usecases/subscription_usecases.dart';
import 'package:app_template/features/paywall/presentation/bloc/checkout_launch.dart';
import 'package:app_template/features/paywall/presentation/bloc/checkout_watch_outcome.dart';

class PaywallCheckoutState {
  const PaywallCheckoutState({this.errorMessage, this.isCheckingOut = false});

  final String? errorMessage;
  final bool isCheckingOut;
}

class PaywallCheckoutCubit extends Cubit<PaywallCheckoutState> {
  PaywallCheckoutCubit({
    required AnalyticsService analytics,
    required PurchaseSuccessReporter purchaseReporter,
    required PendingEventsService pendingEvents,
    required GetSubscriptionUseCase getSubscription,
  }) : _analytics = analytics,
       _purchaseReporter = purchaseReporter,
       _pendingEvents = pendingEvents,
       _getSubscription = getSubscription,
       super(const PaywallCheckoutState());

  final AnalyticsService _analytics;
  final PurchaseSuccessReporter _purchaseReporter;
  final PendingEventsService _pendingEvents;
  final GetSubscriptionUseCase _getSubscription;

  var didSucceed = false;
  String? _lastPlanId;
  Plan? _lastPlan;
  var _skipTrial = false;
  var _loggedPaymentScreen = false;

  List<String> _lastPaymentApps = const [];
  String? _lastSelectedPackageName;
  String? _lastPaymentMethod;

  static InitiatePaymentCustomer? customerFor({
    required String userId,
    required String phone,
    String? displayName,
    String? email,
  }) {
    if (phone.trim().isEmpty) return null;
    final trimmedEmail = email?.trim();
    return InitiatePaymentCustomer(
      externalId: userId,
      name: (displayName?.trim().isNotEmpty == true)
          ? displayName!.trim()
          : 'Subscriber',
      email: (trimmedEmail != null && trimmedEmail.contains('@'))
          ? trimmedEmail
          : '$userId@users.local',
      phone: phone.trim(),
    );
  }

  /// Apps are installed but none selected — QR is only when the device has
  /// no UPI apps.
  static Object? upiSelectionError({
    required bool useQr,
    required bool hasUpiApps,
  }) {
    if (useQr && hasUpiApps) {
      return StateError('Select a UPI app to continue');
    }
    return null;
  }

  /// QR payload or UPI intent URL from an initiate response.
  static CheckoutLaunch resolveLaunch({
    required InitiatePaymentResponse response,
    required bool useQr,
    String? packageName,
  }) {
    if (useQr) {
      final payload = UpiService.qrPayload(response.checkoutLinks);
      if (payload == null || payload.isEmpty) {
        throw StateError('Could not generate a UPI QR code. Please try again.');
      }
      return CheckoutLaunch.qr(response: response, qrPayload: payload);
    }
    final url = UpiService.resolveIntentUrl(
      links: response.checkoutLinks,
      packageName: packageName,
    );
    if (url == null || url.isEmpty) {
      throw StateError('No UPI link returned for this checkout');
    }
    return CheckoutLaunch.intent(
      response: response,
      intentUrl: url,
      packageName: packageName ?? '',
    );
  }

  static String messageForWatchEvent(CheckoutStatusEvent event) {
    if (event.phase == CheckoutWatchPhase.timeout) {
      return 'Payment is still pending. Try again shortly.';
    }
    return 'Payment could not be completed. Please try again.';
  }

  /// Maps a status-watch event to success / QR expiry / failure. Pending is
  /// ignored. Active QR treats timeout and expiry as [CheckoutWatchOutcome.qrExpired].
  static CheckoutWatchOutcome watchOutcome(
    CheckoutStatusEvent event, {
    required bool hasActiveQr,
  }) {
    if (event.phase == CheckoutWatchPhase.pending) {
      return const CheckoutWatchOutcome.ignore();
    }
    if (event.phase == CheckoutWatchPhase.expired ||
        event.phase == CheckoutWatchPhase.timeout) {
      if (hasActiveQr) return const CheckoutWatchOutcome.qrExpired();
      return CheckoutWatchOutcome.failed(
        StateError(messageForWatchEvent(event)),
        useQr: false,
      );
    }
    if (event.isSuccess) {
      return CheckoutWatchOutcome.success(event.checkout);
    }
    return CheckoutWatchOutcome.failed(
      StateError(messageForWatchEvent(event)),
      useQr: true,
    );
  }

  /// UPI returned without a success/error callback. Unlock back / retry.
  void onReturnedFromCheckout() {
    if (state.isCheckingOut) {
      emit(PaywallCheckoutState(errorMessage: state.errorMessage));
    }
  }

  Future<void> onPaymentScreenReady(
    Plan plan, {
    required List<String> paymentApps,
    String? source,
  }) async {
    if (_loggedPaymentScreen) return;
    _loggedPaymentScreen = true;
    _lastPlan = plan;
    _lastPlanId = plan.id;
    await _analytics.logEvent(
      AnalyticsEvents.paymentScreen,
      parameters: PaymentEventProperties.fromPlan(
        plan: plan,
        skipTrial: PaywallSources.isRenewal(source),
        extra: {
          ...PaymentEventProperties.upi(
            paymentApps: paymentApps,
            paymentMethod: paymentApps.isNotEmpty
                ? AnalyticsValues.paymentMethodIntent
                : AnalyticsValues.paymentMethodQr,
          ),
          if (source != null) AnalyticsProperties.source: source,
        },
      ),
    );
  }

  Future<void> onPayStarted(
    Plan plan, {
    required String userId,
    required bool isPremium,
    required bool useQr,
    required List<String> paymentApps,
    String? selectedPackageName,
    String? source,
    String? offerType,
  }) async {
    emit(const PaywallCheckoutState(isCheckingOut: true));
    _lastPlanId = plan.id;
    _lastPlan = plan;
    _skipTrial = PaywallSources.isRenewal(source);
    _rememberPaymentContext(
      paymentApps: paymentApps,
      selectedPackageName: useQr ? null : selectedPackageName,
      paymentMethod: useQr
          ? AnalyticsValues.paymentMethodQrCode
          : AnalyticsValues.paymentMethodLink,
    );
    final amount = PaymentEventProperties.chargedAmountInr(
      plan,
      skipTrial: _skipTrial,
    );
    final known = await _fetchKnownSubscription(userId);
    final planProps = PaymentEventProperties.fromPlan(
      plan: plan,
      skipTrial: _skipTrial,
      extra: _upiEventProps(),
    );
    await _analytics.logEvent(
      AnalyticsEvents.paywallCtaTapped,
      parameters: {
        ...planProps,
        AnalyticsProperties.planCategory: plan.category.apiValue,
        if (source != null) AnalyticsProperties.source: source,
        if (offerType != null) AnalyticsProperties.offerType: offerType,
      },
    );
    await _analytics.logEvent(
      AnalyticsEvents.checkoutStarted,
      parameters: {
        ...planProps,
        AnalyticsProperties.planPrice: amount,
        if (source != null) AnalyticsProperties.source: source,
        ..._subscriptionCounters(known),
      },
    );
    if (userId.isEmpty) return;
    await _purchaseReporter.markInitiated(
      userId: userId,
      planId: plan.id,
      subscriptionStatus: isPremium
          ? AnalyticsValues.premium
          : AnalyticsValues.free,
      amountInr: amount,
      trialAmount: _skipTrial ? 0 : plan.trialAmount,
      subscriptionAmount: plan.priceAmount,
      mediaURL: plan.videoUrl,
      planFrequency: plan.billingCycle,
      isPayAsYouGo: plan.category == PlanCategory.oneTime,
      paymentApps: _lastPaymentApps,
      selectedPackageName: _lastSelectedPackageName,
      paymentMethod: _lastPaymentMethod,
    );
  }

  Future<void> attachCheckout(InitiatePaymentResponse response) {
    return _purchaseReporter.attachCheckout(
      subscriptionId: response.subscriptionId,
      paymentId: analyticsPaymentId(response),
      planId: response.planId,
    );
  }

  Future<void> onPaySuccess(
    InitiatePaymentResponse response, {
    required String userId,
    Plan? plan,
  }) async {
    final chargedAmount = plan
        ?.chargeAmountFor(skipTrial: _skipTrial)
        .toDouble();
    final known = await _fetchKnownSubscription(userId);
    await _purchaseReporter.flushOnStreamSuccess(
      userId: userId,
      subscriptionId: response.subscriptionId,
      paymentId: analyticsPaymentId(response),
      planId: response.planId,
      amountInr: chargedAmount,
    );
    final planProps = plan == null
        ? <String, dynamic>{AnalyticsProperties.planId: response.planId}
        : PaymentEventProperties.fromPlan(
            plan: plan,
            skipTrial: _skipTrial,
            extra: _upiEventProps(),
          );
    final recharge = plan == null || chargedAmount == null
        ? null
        : PaymentEventProperties.rechargeAmountInr(
            plan: plan,
            chargedAmountInr: chargedAmount,
          );
    await _analytics.logEvent(
      AnalyticsEvents.mandateAuthorized,
      parameters: {
        ...planProps,
        AnalyticsProperties.subscriptionId: response.subscriptionId,
        AnalyticsProperties.paymentId: analyticsPaymentId(response),
        if (chargedAmount != null && chargedAmount > 0) ...{
          AnalyticsProperties.planPrice: chargedAmount,
          AnalyticsProperties.amount: chargedAmount,
        },
        if (recharge != null) AnalyticsProperties.rechargeAmount: recharge,
        ..._subscriptionCounters(known),
      },
    );
    await _analytics.setUserProfileProperty(
      AnalyticsUserProperties.firstSubscriptionDate,
      DateTime.now().toIso8601String(),
    );
    await _analytics.setUserProperty(
      AnalyticsUserProperties.subscriptionPlan,
      response.planId,
    );
    await _analytics.setSuperProperty(
      AnalyticsSuperProperties.subscriptionStatus,
      AnalyticsValues.premium,
    );
    didSucceed = true;
    // Do not refresh entitlement here — wait until the success sheet closes.
    emit(const PaywallCheckoutState());
  }

  Future<void> enterAppAfterSuccessfulPurchase(String userId) async {
    await _pendingEvents.onPaymentSucceeded();
  }

  Future<void> onPayError(Object error, {bool? useQr}) async {
    final message = userFacingPaymentMessage(error);
    final isCreate =
        message.toLowerCase().contains('select a upi') ||
        message.toLowerCase().contains('could not generate');
    if (_lastPaymentApps.isEmpty && useQr != null) {
      _rememberPaymentContext(
        paymentApps: const [],
        selectedPackageName: null,
        paymentMethod: useQr
            ? AnalyticsValues.paymentMethodQrCode
            : AnalyticsValues.paymentMethodLink,
      );
    } else if (useQr != null) {
      _lastPaymentMethod = useQr
          ? AnalyticsValues.paymentMethodQrCode
          : AnalyticsValues.paymentMethodLink;
    }
    await _analytics.logEvent(
      isCreate
          ? AnalyticsEvents.subscriptionCreationFailed
          : AnalyticsEvents.paymentFailed,
      parameters: {
        ..._lastPlanFailureProps(),
        AnalyticsProperties.reason: message,
        AnalyticsProperties.errorCode: error.runtimeType.toString(),
        AnalyticsProperties.isCancelled: false,
        ..._upiEventProps(),
      },
    );
    emit(PaywallCheckoutState(errorMessage: message));
  }

  static String userFacingPaymentMessage(Object error) {
    final raw = error is Failure
        ? error.message
        : error.toString().replaceFirst('Bad state: ', '').trim();
    if (raw.isEmpty) {
      return 'Payment could not be completed. Please try again.';
    }
    final lower = raw.toLowerCase();
    if (raw.contains('Exception:') ||
        raw.contains('StateError') ||
        lower.contains('something went wrong') ||
        lower.contains('is not a subtype') ||
        lower.startsWith('http ') ||
        lower.contains('cashfree request failed') ||
        lower.contains('failed to create subscription')) {
      return 'Payment could not be started. Please try again.';
    }
    return raw;
  }

  void _rememberPaymentContext({
    required List<String> paymentApps,
    String? selectedPackageName,
    required String paymentMethod,
  }) {
    _lastPaymentApps = List<String>.from(paymentApps);
    _lastSelectedPackageName = selectedPackageName;
    _lastPaymentMethod = paymentMethod;
  }

  Map<String, dynamic> _upiEventProps() => PaymentEventProperties.upi(
    paymentApps: _lastPaymentApps,
    selectedPackageName: _lastSelectedPackageName,
    paymentMethod: _lastPaymentMethod ?? AnalyticsValues.paymentMethodQrCode,
  );

  Future<Subscription?> _fetchKnownSubscription(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final result = await _getSubscription(
        GetSubscriptionParams(userId: userId),
      );
      return result.fold((_) => null, (subscription) => subscription);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _lastPlanFailureProps() {
    final plan = _lastPlan;
    if (plan != null) {
      return {
        ...PaymentEventProperties.fromPlan(plan: plan, skipTrial: _skipTrial),
        AnalyticsProperties.rechargeType: PaymentEventProperties.rechargeType(
          plan,
        ),
      };
    }
    return {if (_lastPlanId != null) AnalyticsProperties.planId: _lastPlanId};
  }

  Map<String, dynamic> _subscriptionCounters(Subscription? subscription) => {
    if (subscription?.status != null)
      AnalyticsProperties.status: subscription!.status,
    if (subscription?.paidCount != null)
      AnalyticsProperties.paidCount: subscription!.paidCount,
    if (subscription?.remainingCount != null)
      AnalyticsProperties.remainingCount: subscription!.remainingCount,
  };
}
