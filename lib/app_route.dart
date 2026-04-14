import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/main/locations/splash_location.dart';

import 'package:trocado/src/presentation/observers/logger_navigation_observer.dart';

@immutable
final class AppRoutes {
  final String path;
  final String name;
  final RegExp regex;

  const AppRoutes._({
    required this.path,
    required this.name,
    required this.regex,
  });

  static final date = AppRoutes._(
    path: '/date',
    name: 'date-route',
    regex: RegExp(r'/date$'),
  );

  static final exit = AppRoutes._(
    path: '/exit',
    name: 'exit-route',
    regex: RegExp(r'/exit$'),
  );

  static final home = AppRoutes._(
    path: '/home',
    name: 'home-route',
    regex: RegExp(r'^/$'),
  );

  static final splash = AppRoutes._(
    path: '/splash',
    name: 'splash-route',
    regex: RegExp(r'/splash'),
  );

  static final category = AppRoutes._(
    path: '/category',
    name: 'category-route',
    regex: RegExp(r'^/category$'),
  );

  static final calculator = AppRoutes._(
    path: '/calculator',
    name: 'calculator-route',
    regex: RegExp(r'^/calculator$'),
  );

  static final expense = AppRoutes._(
    path: '/expense',
    name: 'expense-route',
    regex: RegExp(r'^/expense$'),
  );

  static final budget = AppRoutes._(
    path: '/budget',
    name: 'budget-route',
    regex: RegExp(r'^/budget$'),
  );

  static final signIn = AppRoutes._(
    path: '/sign-in',
    name: 'sign-in-route',
    regex: RegExp(r'^/sign-in$'),
  );

  static final signUp = AppRoutes._(
    path: '/sign-up',
    name: 'sign-up-route',
    regex: RegExp(r'^/sign-up$'),
  );

  static final forgotPassword = AppRoutes._(
    path: '/forgot-password',
    name: 'forgot-password-route',
    regex: RegExp(r'^/forgot-password$'),
  );

  static final _all = [
    date,
    exit,
    home,
    budget,
    splash,
    signIn,
    signUp,
    expense,
    category,
    calculator,
    forgotPassword,
  ];

  static AppRoutes? match(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location));
}

final routerConfig = DuckRouter(
  initialLocation: SplashLocation(),
  navigatorObserverBuilder: (_) => [LoggerNavigatorObserver()],
);
