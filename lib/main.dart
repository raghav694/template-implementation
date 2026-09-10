import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_template/app.dart';
import 'package:app_template/core/crashlytics/crashlytics_service.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/firebase/firebase_initializer.dart';
import 'package:app_template/core/growthbook/growthbook_service.dart';
import 'package:app_template/core/notifications/background_message_handler.dart';
import 'package:app_template/core/remote_config/remote_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseInitializer.initialize();

  if (FirebaseInitializer.isInitialized) {
    await CrashlyticsService.initialize();
    await RemoteConfigService.initialize();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  await configureDependencies();
  unawaited(getIt<GrowthBookService>().initialize());
  runApp(const App());
}
