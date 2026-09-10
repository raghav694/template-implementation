import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts one or more streams (Bloc/Cubit) into a [Listenable] for go_router.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Iterable<Stream<dynamic>> streams) {
    for (final stream in streams) {
      _subscriptions.add(
        stream.listen((_) {
          if (!_disposed) notifyListeners();
        }),
      );
    }
    scheduleMicrotask(() {
      if (!_disposed) notifyListeners();
    });
  }

  final _subscriptions = <StreamSubscription<dynamic>>[];
  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
