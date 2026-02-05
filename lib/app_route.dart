import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/main/locations/splash_location.dart';

import 'package:trocado/src/presentation/observers/logger_navigation_observer.dart';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

@immutable
final class RoutesConstant {
  final String path;
  final String name;
  final RegExp regex;

  const RoutesConstant._({
    required this.path,
    required this.name,
    required this.regex,
  });

  static final date = RoutesConstant._(
    path: '/date',
    name: 'date-route',
    regex: RegExp(r'/date$'),
  );

  static final exit = RoutesConstant._(
    path: '/exit',
    name: 'exit-route',
    regex: RegExp(r'/exit$'),
  );

  static final home = RoutesConstant._(
    path: '/home',
    name: 'home-route',
    regex: RegExp(r'^/$'),
  );

  static final splash = RoutesConstant._(
    path: '/splash',
    name: 'splash-route',
    regex: RegExp(r'/splash'),
  );

  static final category = RoutesConstant._(
    path: '/category',
    name: 'category-route',
    regex: RegExp(r'^/category$'),
  );

  static final calculator = RoutesConstant._(
    path: '/calculator',
    name: 'calculator-route',
    regex: RegExp(r'^/calculator$'),
  );

  static final transactions = RoutesConstant._(
    path: '/transactions',
    name: 'transactions-route',
    regex: RegExp(r'^/transactions$'),
  );

  static final _all = [
    date,
    exit,
    home,
    splash,
    category,
    calculator,
    transactions,
  ];

  static RoutesConstant? match(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location));
}

final routerConfig = DuckRouter(
  initialLocation: SplashLocation(),
  navigatorObserverBuilder: (_) => [LoggerNavigatorObserver()],
  onDeepLink: (uri, _) {
    // adb shell am start -a android.intent.action.VIEW -d "trocado://app/settings"

    return [];
  },
);
