import 'dart:developer';

import 'package:flutter/widgets.dart';

final class LoggerNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(route.settings.name, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(route.settings.name, 'pop');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute == null) return;

    _log(newRoute.settings.name, 'replace');
  }

  void _log(String? routeName, String action) {
    if (routeName == null) return;

    log('Screen $action: $routeName');
  }
}
