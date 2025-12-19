import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

@immutable
final class RoutesConstant {
  final String path;
  final String name;
  final RegExp regex;
  final bool shouldShowBottomNavigation;

  const RoutesConstant._({
    required this.path,
    required this.name,
    required this.regex,
    this.shouldShowBottomNavigation = false,
  });

  static final core = RoutesConstant._(
    path: '/core',
    name: 'core-route',
    regex: RegExp(r'/core$'),
    shouldShowBottomNavigation: true,
  );

  static final splash = RoutesConstant._(
    path: '/splash',
    name: 'splash-route',
    regex: RegExp(r'/splash'),
  );

  static final home = RoutesConstant._(
    path: '/home',
    name: 'home-route',
    regex: RegExp(r'^/$'),
    shouldShowBottomNavigation: true,
  );

  static final user = RoutesConstant._(
    path: '/user',
    name: 'user-route',
    regex: RegExp(r'^/user$'),
    shouldShowBottomNavigation: true,
  );

  static final wallets = RoutesConstant._(
    path: '/wallets',
    name: 'wallets-route',
    regex: RegExp(r'^/wallets$'),
  );

  static final debts = RoutesConstant._(
    path: '/debts',
    name: 'debts-route',
    regex: RegExp(r'^/debts$'),
  );

  static final goals = RoutesConstant._(
    path: '/goals',
    name: 'goals-route',
    regex: RegExp(r'^/goals$'),
  );

  static final images = RoutesConstant._(
    path: '/images',
    name: 'images-route',
    regex: RegExp(r'^/images$'),
  );

  static final reports = RoutesConstant._(
    path: '/reports',
    name: 'reports-route',
    regex: RegExp(r'^/reports$'),
    shouldShowBottomNavigation: true,
  );

  static final settings = RoutesConstant._(
    path: '/settings',
    name: 'settings-route',
    regex: RegExp(r'^/settings$'),
    shouldShowBottomNavigation: true,
  );

  static final calculator = RoutesConstant._(
    path: '/calculator',
    name: 'calculator-route',
    regex: RegExp(r'^/calculator$'),
  );

  static final categories = RoutesConstant._(
    path: '/categories',
    name: 'categories-route',
    regex: RegExp(r'^/categories$'),
  );

  static final transactions = RoutesConstant._(
    path: '/transactions',
    name: 'transactions-route',
    regex: RegExp(r'^/transactions$'),
  );

  static final allTransaction = RoutesConstant._(
    path: '/all/transaction',
    name: 'all-transaction-route',
    shouldShowBottomNavigation: true,
    regex: RegExp(r'^/all/transaction$'),
  );

  static final onboarding = RoutesConstant._(
    path: '/onboarding',
    name: 'onboarding-route',
    regex: RegExp(r'^/onboarding$'),
  );

  static final onboardingStepTheme = RoutesConstant._(
    path: '/onboarding/step/theme',
    name: 'onboarding-step-theme-route',
    regex: RegExp(r'^/onboarding/step/theme$'),
  );

  static final onboardingStepWallet = RoutesConstant._(
    path: '/onboarding/step/wallet',
    name: 'onboarding-step-wallet-route',
    regex: RegExp(r'^/onboarding/step/wallet$'),
  );

  static final onboardingStepProfile = RoutesConstant._(
    path: '/onboarding/step/profile',
    name: 'onboarding-step-profile-route',
    regex: RegExp(r'^/onboarding/step/profile$'),
  );

  static final recurringTransactions = RoutesConstant._(
    path: '/recurring/transactions',
    name: 'recurring-transactions-route',
    regex: RegExp(r'^/recurring/transactions$'),
  );

  static final _all = [
    core,
    home,
    user,
    debts,
    goals,
    images,
    splash,
    reports,
    wallets,
    settings,
    calculator,
    categories,
    onboarding,
    transactions,
    allTransaction,
    onboardingStepTheme,
    onboardingStepWallet,
    onboardingStepProfile,
    recurringTransactions,
  ];

  static RoutesConstant? match(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location));

  static bool needsShowBottomNavigation(String path) =>
      _all
          .firstWhereOrNull((route) => route.regex.hasMatch(path))
          ?.shouldShowBottomNavigation ??
      false;
}
