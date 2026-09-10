import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:app_template/core/app_update/app_update_service.dart';
import 'package:app_template/core/di/injection.dart';

/// App Store update dialog on the post-login home shell (iOS only).
///
/// [UpgradeAlert] compares [pubspec] version to the live listing. Country is
/// the device locale — not a hardcoded storefront.
class IosStoreUpgradeGate extends StatefulWidget {
  const IosStoreUpgradeGate({required this.child, super.key});

  final Widget child;

  @override
  State<IosStoreUpgradeGate> createState() => _IosStoreUpgradeGateState();
}

class _IosStoreUpgradeGateState extends State<IosStoreUpgradeGate> {
  @override
  void initState() {
    super.initState();
    if (_isIos) {
      unawaited(getIt<AppUpdateService>().refreshStatus());
    }
  }

  static bool get _isIos => !kIsWeb && Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    if (!_isIos) return widget.child;

    return ValueListenableBuilder<AppConfigStatus>(
      valueListenable: getIt<AppUpdateService>().status,
      builder: (context, status, child) {
        final country =
            WidgetsBinding.instance.platformDispatcher.locale.countryCode;
        return UpgradeAlert(
          upgrader: Upgrader(
            debugLogging: kDebugMode,
            countryCode: (country != null && country.isNotEmpty)
                ? country
                : null,
            durationUntilAlertAgain: status.forceUpdate
                ? Duration.zero
                : const Duration(days: 3),
          ),
          showIgnore: false,
          showLater: !status.forceUpdate,
          dialogStyle: UpgradeDialogStyle.cupertino,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}
