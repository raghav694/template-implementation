import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PaymentStatusPhase { processing, success, failed }

class PaymentStatusView {
  const PaymentStatusView({required this.phase, this.errorMessage});

  final PaymentStatusPhase phase;
  final String? errorMessage;
}

/// Checkout result sheet. Starts as processing after UPI return, then the
/// same sheet becomes success or failed when status arrives.
class PaymentStatusBottomSheet extends StatefulWidget {
  const PaymentStatusBottomSheet({
    super.key,
    required this.view,
    this.onCancel,
  });

  final ValueListenable<PaymentStatusView> view;
  final VoidCallback? onCancel;

  @override
  State<PaymentStatusBottomSheet> createState() =>
      _PaymentStatusBottomSheetState();
}

class _PaymentStatusBottomSheetState extends State<PaymentStatusBottomSheet> {
  var _closing = false;

  @override
  void initState() {
    super.initState();
    widget.view.addListener(_onViewChanged);
    _onViewChanged();
  }

  @override
  void dispose() {
    widget.view.removeListener(_onViewChanged);
    super.dispose();
  }

  void _onViewChanged() {
    final phase = widget.view.value.phase;
    if (phase == PaymentStatusPhase.processing || _closing) return;
    _closing = true;
    if (phase == PaymentStatusPhase.success) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PaymentStatusView>(
      valueListenable: widget.view,
      builder: (context, view, _) {
        return PopScope(
          canPop: view.phase != PaymentStatusPhase.processing,
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.5,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              top: false,
              child: switch (view.phase) {
                PaymentStatusPhase.processing => _ProcessingState(
                  onCancel: widget.onCancel,
                ),
                PaymentStatusPhase.success => const _SuccessState(),
                PaymentStatusPhase.failed => _FailedState(
                  message:
                      view.errorMessage ??
                      'Payment could not be completed. Please try again.',
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _ProcessingState extends StatelessWidget {
  const _ProcessingState({this.onCancel});

  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Processing payment',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'We are confirming your payment.',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodySmall,
            ),
            if (onCancel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancel payment',
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 60,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Payment successful',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your plan is now active.',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FailedState extends StatelessWidget {
  const _FailedState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Text(
                '!',
                style: AppTypography.textTheme.displayLarge?.copyWith(
                  color: AppColors.error,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Payment failed',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
