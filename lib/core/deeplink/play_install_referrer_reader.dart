import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

abstract class PlayInstallReferrerReader {
  Future<String?> read();
}

class PlayInstallReferrerReaderImpl implements PlayInstallReferrerReader {
  @override
  Future<String?> read() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final details = await PlayInstallReferrer.installReferrer.timeout(
        const Duration(seconds: 5),
      );
      final referrer = details.installReferrer?.trim();
      if (referrer == null || referrer.isEmpty) return null;
      return referrer;
    } catch (_) {
      return null;
    }
  }
}
