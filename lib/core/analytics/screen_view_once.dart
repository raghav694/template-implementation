import 'package:flutter/widgets.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/analytics/analytics_service.dart';

/// Fires [eventName] exactly once per navigation to this screen (on first
/// build, via `didChangeDependencies`), then renders [child] unchanged.
///
/// For screens whose `build` method is too large/entrenched to convert to a
/// stateful widget just to add a fire-once guard — wrap the returned widget
/// tree in this instead of restructuring the whole screen.
class ScreenViewOnce extends StatefulWidget {
  const ScreenViewOnce({
    super.key,
    required this.eventName,
    required this.child,
  });

  final String eventName;
  final Widget child;

  @override
  State<ScreenViewOnce> createState() => _ScreenViewOnceState();
}

class _ScreenViewOnceState extends State<ScreenViewOnce> {
  var _logged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logged) return;
    _logged = true;
    getIt<AnalyticsService>().logEvent(widget.eventName);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
