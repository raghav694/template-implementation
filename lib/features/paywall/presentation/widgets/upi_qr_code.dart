import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UpiQrCode extends StatelessWidget {
  const UpiQrCode({
    super.key,
    required this.data,
    this.size = 200,
    this.expired = false,
    this.remaining,
    this.onCancel,
  });

  final String data;
  final double size;
  final bool expired;
  final Duration? remaining;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: expired ? 0.28 : 1,
              child: ColoredBox(
                color: Colors.white,
                child: QrImageView(
                  data: data,
                  size: size,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            if (expired)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size - 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    child: Text(
                      'This QR code has expired',
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          expired
              ? 'Cancel and try again for a new code.'
              : _formatRemaining(remaining ?? Duration.zero),
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onCancel,
            child: Text(
              'Cancel payment',
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatRemaining(Duration remaining) {
    final seconds = remaining.inSeconds.clamp(0, 24 * 60 * 60);
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }
}
