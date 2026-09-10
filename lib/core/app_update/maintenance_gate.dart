import 'package:flutter/material.dart';

import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:app_template/core/app_update/app_update_service.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/shared/widgets/maintenance_screen.dart';

/// Full-screen maintenance copy when `is_app_under_maintenance` is true.
class MaintenanceGate extends StatelessWidget {
  const MaintenanceGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppConfigStatus>(
      valueListenable: getIt<AppUpdateService>().status,
      builder: (context, status, child) {
        if (!status.isUnderMaintenance) return child!;
        return MaintenanceScreen(title: status.title, message: status.message);
      },
      child: child,
    );
  }
}
