import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, 14, AppSpacing.xl, 8),
      child: Row(children: [AppLogo(size: 32, showName: true)]),
    );
  }
}
