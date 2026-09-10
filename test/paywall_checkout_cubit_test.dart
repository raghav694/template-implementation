import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/constants/paywall_sources.dart';
import 'package:app_template/features/analytics/pending_events_service.dart';
import 'package:app_template/features/analytics/pending_purchase_cache.dart';
import 'package:app_template/features/analytics/purchase_success_reporter.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/usecases/subscription_usecases.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_checkout_cubit.dart';
import 'package:capslock_payments_sdk/capslock_payments_sdk.dart' hide Plan;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_pending_events_datasource.dart';
import 'fakes/fake_subscription_repository.dart';
import 'fakes/recording_analytics_service.dart';

void main() {
  const plan = Plan(
    id: 'monthly',
    label: 'Monthly',
    priceAmount: 149,
    billingCycle: 'month',
    trialDays: 7,
    trialAmount: 1,
    videoUrl: 'https://cdn.example/hero.mp4',
  );

  late RecordingAnalyticsService analytics;
  late PaywallCheckoutCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    analytics = RecordingAnalyticsService();
    final prefs = await SharedPreferences.getInstance();
    final cache = PendingPurchaseCache(prefs: prefs);
    cubit = PaywallCheckoutCubit(
      analytics: analytics,
      purchaseReporter: PurchaseSuccessReporter(cache, analytics),
      pendingEvents: PendingEventsService(
        FakePendingEventsDataSource(),
        analytics,
        cache: cache,
      ),
      getSubscription: GetSubscriptionUseCase(FakeSubscriptionRepository()),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('maps Cashfree / HTTP noise to a start-failed message', () {
    expect(
      PaywallCheckoutCubit.userFacingPaymentMessage(
        StateError('cashfree request failed'),
      ),
      'Payment could not be started. Please try again.',
    );
    expect(
      PaywallCheckoutCubit.userFacingPaymentMessage('HTTP 500'),
      'Payment could not be started. Please try again.',
    );
  });

  test('keeps a user-facing payment message', () {
    expect(
      PaywallCheckoutCubit.userFacingPaymentMessage(
        'Payment is still pending. Try again shortly.',
      ),
      'Payment is still pending. Try again shortly.',
    );
  });

  test('paymentScreen uses INTENT when UPI apps exist', () async {
    await cubit.onPaymentScreenReady(plan, paymentApps: const ['GPay']);
    await cubit.onPaymentScreenReady(plan, paymentApps: const []);

    expect(analytics.logged, hasLength(1));
    final event = analytics.logged.single;
    expect(event.name, AnalyticsEvents.paymentScreen);
    expect(
      event.parameters?[AnalyticsProperties.paymentMethod],
      AnalyticsValues.paymentMethodIntent,
    );
    expect(event.parameters?[AnalyticsProperties.paymentApps], ['GPay']);
    expect(event.parameters?[AnalyticsProperties.trialAmount], 1);
  });

  test('checkoutStarted uses qrcode and drops package name for QR', () async {
    await cubit.onPayStarted(
      plan,
      userId: 'user_1',
      isPremium: false,
      useQr: true,
      paymentApps: const ['GPay', 'PhonePe'],
      selectedPackageName: 'com.phonepe.app',
    );

    final started = analytics.logged.firstWhere(
      (event) => event.name == AnalyticsEvents.checkoutStarted,
    );
    expect(
      started.parameters?[AnalyticsProperties.paymentMethod],
      AnalyticsValues.paymentMethodQrCode,
    );
    expect(
      started.parameters?.containsKey(AnalyticsProperties.selectedPackageName),
      isFalse,
    );
    expect(started.parameters?[AnalyticsProperties.paymentApps], [
      'GPay',
      'PhonePe',
    ]);
    expect(started.parameters?[AnalyticsProperties.trialAmount], 1);
    expect(started.parameters?[AnalyticsProperties.subscriptionAmount], 149);
    expect(
      started.parameters?[AnalyticsProperties.mediaURL],
      'https://cdn.example/hero.mp4',
    );
    expect(started.parameters?[AnalyticsProperties.planFrequency], 'month');
  });

  test('renewal checkout uses link method and zeroes trialAmount', () async {
    await cubit.onPayStarted(
      plan,
      userId: 'user_1',
      isPremium: false,
      useQr: false,
      paymentApps: const ['GPay'],
      selectedPackageName: 'com.google.android.apps.nbu.paisa.user',
      source: PaywallSources.renewal,
    );

    final started = analytics.logged.firstWhere(
      (event) => event.name == AnalyticsEvents.checkoutStarted,
    );
    expect(
      started.parameters?[AnalyticsProperties.paymentMethod],
      AnalyticsValues.paymentMethodLink,
    );
    expect(
      started.parameters?[AnalyticsProperties.selectedPackageName],
      'com.google.android.apps.nbu.paisa.user',
    );
    expect(started.parameters?[AnalyticsProperties.trialAmount], 0);
    expect(started.parameters?[AnalyticsProperties.planPrice], 149);
  });

  test('paymentFailed reuses last UPI context', () async {
    await cubit.onPayStarted(
      plan,
      userId: 'user_1',
      isPremium: false,
      useQr: false,
      paymentApps: const ['PhonePe'],
      selectedPackageName: 'com.phonepe.app',
    );
    analytics.logged.clear();

    await cubit.onPayError(StateError('Payment was cancelled'));
    final failed = analytics.logged.single;
    expect(failed.name, AnalyticsEvents.paymentFailed);
    expect(failed.parameters?[AnalyticsProperties.paymentApps], ['PhonePe']);
    expect(
      failed.parameters?[AnalyticsProperties.paymentMethod],
      AnalyticsValues.paymentMethodLink,
    );
    expect(failed.parameters?[AnalyticsProperties.trialAmount], 1);
    expect(failed.parameters?[AnalyticsProperties.subscriptionAmount], 149);
    expect(
      failed.parameters?[AnalyticsProperties.mediaURL],
      'https://cdn.example/hero.mp4',
    );
    expect(
      failed.parameters?[AnalyticsProperties.rechargeType],
      AnalyticsValues.rechargeTypeSubs,
    );
  });

  test('upiSelectionError only when apps exist but none is selected', () {
    expect(
      PaywallCheckoutCubit.upiSelectionError(useQr: true, hasUpiApps: true),
      isA<StateError>(),
    );
    expect(
      PaywallCheckoutCubit.upiSelectionError(useQr: true, hasUpiApps: false),
      isNull,
    );
    expect(
      PaywallCheckoutCubit.upiSelectionError(useQr: false, hasUpiApps: true),
      isNull,
    );
  });

  test('resolveLaunch maps QR payload and intent URL', () {
    final qr = PaywallCheckoutCubit.resolveLaunch(
      response: _checkout(qrData: 'upi://pay?pa=demo@upi'),
      useQr: true,
    );
    expect(qr.useQr, isTrue);
    expect(qr.qrPayload, 'upi://pay?pa=demo@upi');

    final intent = PaywallCheckoutCubit.resolveLaunch(
      response: _checkout(intentUrl: 'upi://pay?pa=gpay'),
      useQr: false,
      packageName: 'com.google.android.apps.nbu.paisa.user',
    );
    expect(intent.useQr, isFalse);
    expect(intent.intentUrl, 'upi://pay?pa=gpay');
  });

  test('resolveLaunch throws when QR or intent is missing', () {
    expect(
      () => PaywallCheckoutCubit.resolveLaunch(
        response: _checkout(),
        useQr: true,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => PaywallCheckoutCubit.resolveLaunch(
        response: _checkout(),
        useQr: false,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('watchOutcome ignores pending and expires an active QR', () {
    final checkout = _checkout();
    expect(
      PaywallCheckoutCubit.watchOutcome(
        CheckoutStatusEvent(
          checkout: checkout,
          status: 'PENDING',
          phase: CheckoutWatchPhase.pending,
        ),
        hasActiveQr: false,
      ).isIgnore,
      isTrue,
    );
    expect(
      PaywallCheckoutCubit.watchOutcome(
        CheckoutStatusEvent(
          checkout: checkout,
          status: 'LINK_EXPIRED',
          phase: CheckoutWatchPhase.expired,
        ),
        hasActiveQr: true,
      ).isQrExpired,
      isTrue,
    );
    final failed = PaywallCheckoutCubit.watchOutcome(
      CheckoutStatusEvent(
        checkout: checkout,
        status: 'FAILED',
        phase: CheckoutWatchPhase.failure,
      ),
      hasActiveQr: false,
    );
    expect(failed.isFailed, isTrue);
    expect(failed.useQr, isTrue);
    final success = PaywallCheckoutCubit.watchOutcome(
      CheckoutStatusEvent(
        checkout: checkout,
        status: 'ACTIVE',
        phase: CheckoutWatchPhase.success,
      ),
      hasActiveQr: false,
    );
    expect(success.isSuccess, isTrue);
    expect(success.checkout, checkout);
  });
}

InitiatePaymentResponse _checkout({String qrData = '', String intentUrl = ''}) {
  return InitiatePaymentResponse(
    paymentId: 'pay_1',
    subscriptionId: 'sub_1',
    customerId: 'cus',
    planId: 'monthly',
    provider: 'CASHFREE',
    type: 'RECURRING',
    status: 'PENDING',
    gatewaySubscriptionId: 'gw_sub',
    gatewayOrderId: 'ord_1',
    checkoutSessionId: 'cs',
    checkoutLinks: CheckoutLinks(
      android: {if (intentUrl.isNotEmpty) 'DEFAULT': intentUrl},
      ios: const {},
      url: intentUrl,
      qrData: qrData,
    ),
    nextBillingAt: '',
  );
}
