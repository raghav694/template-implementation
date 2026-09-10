import 'dart:io' show Platform, exit;

import 'package:flutter/foundation.dart';

import 'package:app_template/core/app_update/app_config_status.dart';
import 'package:app_template/core/app_update/app_config_status_source.dart';
import 'package:app_template/core/app_update/play_in_app_updater.dart';
import 'package:app_template/core/growthbook/growthbook_service.dart';

/// Android Play in-app updates when force-update is on (Remote Config /
/// config API `force_update` **or** GrowthBook `forceUpdate`).
///
/// Launch and resume both prompt only when force is on. Immediate is
/// preferred; flexible otherwise. Deny retries up to [_maxForceRetries].
/// Immediate success calls [onImmediateUpdateInstalled] (`exit(0)` by default).
///
/// iOS uses [UpgradeAlert] on the home shell with `showLater` off when force
/// is on. Maintenance is unchanged ([MaintenanceGate]).
class AppUpdateService {
  AppUpdateService({
    required AppConfigStatusSource statusSource,
    PlayInAppUpdater playUpdater = const PlayInAppUpdaterImpl(),
    GrowthBookService? growthBook,
    bool Function()? isAndroid,
    void Function()? onImmediateUpdateInstalled,
  }) : _statusSource = statusSource,
       _play = playUpdater,
       _growthBook = growthBook,
       _isAndroid = isAndroid ?? _defaultIsAndroid,
       _onImmediateUpdateInstalled =
           onImmediateUpdateInstalled ?? _defaultExitAfterImmediate;

  final AppConfigStatusSource _statusSource;
  final PlayInAppUpdater _play;
  final GrowthBookService? _growthBook;
  final bool Function() _isAndroid;
  final void Function() _onImmediateUpdateInstalled;

  final ValueNotifier<AppConfigStatus> status = ValueNotifier(
    AppConfigStatus.idle,
  );

  static bool _defaultIsAndroid() => !kIsWeb && Platform.isAndroid;

  static void _defaultExitAfterImmediate() => exit(0);

  Future<AppConfigStatus> refreshStatus() async {
    try {
      status.value = await _statusSource.fetch();
    } catch (_) {
      // Keep the last known flags. Missing config must not block the app.
    }
    await _mergeGrowthBookForceUpdate();
    return status.value;
  }

  Future<void> _mergeGrowthBookForceUpdate() async {
    final growthBook = _growthBook;
    if (growthBook == null) return;
    await growthBook.initializeIfNeeded();
    if (kDebugMode) {
      growthBook.logDebugState(context: 'appUpdate');
    }
    if (!growthBook.isForceUpdate() || status.value.forceUpdate) return;
    status.value = status.value.copyWith(forceUpdate: true);
  }

  /// Splash path: Play prompt only when force-update is on.
  Future<void> checkOnLaunch() => checkForceUpdate();

  /// Foreground resume: Play prompt only when force-update is on.
  Future<void> checkForceUpdate() async {
    final flags = await refreshStatus();
    await _promptPlayUpdate(forceUpdate: flags.forceUpdate);
  }

  static const _maxForceRetries = 3;

  Future<void> _promptPlayUpdate({
    required bool forceUpdate,
    int attempt = 0,
  }) async {
    if (!_isAndroid()) return;
    if (!forceUpdate) return;

    try {
      final info = await _play.check();
      if (!info.updateAvailable) return;

      if (info.immediateAllowed) {
        final result = await _play.performImmediate();
        if (result == StoreUpdateResult.userDenied &&
            attempt < _maxForceRetries) {
          await _promptPlayUpdate(
            forceUpdate: forceUpdate,
            attempt: attempt + 1,
          );
        } else if (result == StoreUpdateResult.success) {
          _onImmediateUpdateInstalled();
        }
        return;
      }

      if (!info.flexibleAllowed) return;

      final result = await _play.startFlexible();
      if (result == StoreUpdateResult.success) {
        await _play.completeFlexible();
      } else if (result == StoreUpdateResult.userDenied &&
          attempt < _maxForceRetries) {
        await _promptPlayUpdate(forceUpdate: forceUpdate, attempt: attempt + 1);
      }
    } catch (_) {}
  }

  void dispose() => status.dispose();
}
