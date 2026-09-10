import 'package:app_template/core/theme/app_colors.dart';
import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';
import 'package:flutter/material.dart';

class UpiAppIcon extends StatelessWidget {
  const UpiAppIcon({super.key, required this.app, this.size = 32});

  final UpiAppInfo app;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = app.iconBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _placeholder(size),
      );
    }
    return _placeholder(size);
  }

  static Widget _placeholder(double size) {
    return Icon(
      Icons.account_balance_wallet_outlined,
      size: size,
      color: AppColors.textSecondary,
    );
  }
}
