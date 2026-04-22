import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/main/deep_link/deep_link_handler.dart';

import 'package:trocado/src/presentation/screens/splash/splash_location.dart';
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

  static final forgotPasswordSuccess = AppRoutes._(
    path: '/forgot-password-success',
    name: 'forgot-password-success-route',
    regex: RegExp(r'^/forgot-password-success$'),
  );

  static final passwordResetConfirm = AppRoutes._(
    path: '/reset-password',
    name: 'password-reset-confirm-route',
    regex: RegExp(r'^/reset-password'),
  );

  static final settings = AppRoutes._(
    path: '/settings',
    name: 'settings-route',
    regex: RegExp(r'^/settings$'),
  );

  static final notifications = AppRoutes._(
    path: '/notifications',
    name: 'notifications-route',
    regex: RegExp(r'^/notifications$'),
  );

  static final budgetDate = AppRoutes._(
    path: '/budget-date',
    name: 'budget-date-route',
    regex: RegExp(r'^/budget-date$'),
  );

  static final expenseDate = AppRoutes._(
    path: '/expense-date',
    name: 'expense-date-route',
    regex: RegExp(r'^/expense-date$'),
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
    settings,
    calculator,
    budgetDate,
    expenseDate,
    notifications,
    forgotPassword,
    passwordResetConfirm,
    forgotPasswordSuccess,
  ];

  static AppRoutes? match(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location));
}

final routerConfig = DuckRouter(
  initialLocation: SplashLocation(),
  onDeepLink: (uri, _) => const DeepLinkHandler()(uri),
  navigatorObserverBuilder: (_) => [LoggerNavigatorObserver()],
);
