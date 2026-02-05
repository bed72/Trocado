import 'package:flutter/material.dart';

import 'package:trocado/app_route.dart';

import 'package:back_button_interceptor/back_button_interceptor.dart';

mixin BackButtonMixin<T extends StatefulWidget> on State<T> {
  void execute();

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(_execute, context: context);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(_execute);
    super.dispose();
  }

  bool _execute(bool _, RouteInfo info) {
    final routeName = info.currentRoute(context)?.settings.name;

    if ([RoutesConstant.home.path].contains(routeName)) {
      execute();

      return true;
    }

    return false;
  }
}
