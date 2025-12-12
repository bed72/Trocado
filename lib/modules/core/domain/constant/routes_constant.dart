import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

@immutable
final class RoutesConstant {
  final bool auth;
  final String path;
  final String name;
  final RegExp regex;

  const RoutesConstant._({
    required this.auth,
    required this.path,
    required this.name,
    required this.regex,
  });

  static final core = RoutesConstant._(
    auth: false,
    path: '/core',
    name: 'core-route',
    regex: RegExp(r'/core$'),
  );

  static final splash = RoutesConstant._(
    auth: false,
    path: '/splash',
    name: 'splash-route',
    regex: RegExp(r'/splash'),
  );

  static final home = RoutesConstant._(
    auth: true,
    path: '/home',
    name: 'home-route',
    regex: RegExp(r'^/$'),
  );

  static final user = RoutesConstant._(
    auth: true,
    path: '/user',
    name: 'user-route',
    regex: RegExp(r'^/user$'),
  );

  static final wallets = RoutesConstant._(
    auth: true,
    path: '/wallets',
    name: 'wallets-route',
    regex: RegExp(r'^/wallets$'),
  );

  static final debts = RoutesConstant._(
    auth: true,
    path: '/debts',
    name: 'debts-route',
    regex: RegExp(r'^/debts$'),
  );

  static final goals = RoutesConstant._(
    auth: true,
    path: '/goals',
    name: 'goals-route',
    regex: RegExp(r'^/goals$'),
  );

  static final images = RoutesConstant._(
    auth: true,
    path: '/images',
    name: 'images-route',
    regex: RegExp(r'^/images$'),
  );

  static final reports = RoutesConstant._(
    auth: true,
    path: '/reports',
    name: 'reports-route',
    regex: RegExp(r'^/reports$'),
  );

  static final settings = RoutesConstant._(
    auth: true,
    path: '/settings',
    name: 'settings-route',
    regex: RegExp(r'^/settings$'),
  );

  static final calculator = RoutesConstant._(
    auth: true,
    path: '/calculator',
    name: 'calculator-route',
    regex: RegExp(r'^/calculator$'),
  );

  static final categories = RoutesConstant._(
    auth: true,
    path: '/categories',
    name: 'categories-route',
    regex: RegExp(r'^/categories$'),
  );

  static final transactions = RoutesConstant._(
    auth: true,
    path: '/transactions',
    name: 'transactions-route',
    regex: RegExp(r'^/transactions$'),
  );

  static final allTransaction = RoutesConstant._(
    auth: true,
    path: '/all/transaction',
    name: 'all-transaction-route',
    regex: RegExp(r'^/all/transaction$'),
  );

  static final onboarding = RoutesConstant._(
    auth: false,
    path: '/onboarding',
    name: 'onboarding-route',
    regex: RegExp(r'^/onboarding$'),
  );

  static final onboardingStepTheme = RoutesConstant._(
    auth: false,
    path: '/onboarding/step/theme',
    name: 'onboarding-step-theme-route',
    regex: RegExp(r'^/onboarding/step/theme$'),
  );

  static final onboardingStepWallet = RoutesConstant._(
    auth: false,
    path: '/onboarding/step/wallet',
    name: 'onboarding-step-wallet-route',
    regex: RegExp(r'^/onboarding/step/wallet$'),
  );

  static final onboardingStepProfile = RoutesConstant._(
    auth: false,
    path: '/onboarding/step/profile',
    name: 'onboarding-step-profile-route',
    regex: RegExp(r'^/onboarding/step/profile$'),
  );

  static final typeTransaction = RoutesConstant._(
    auth: true,
    name: 'type-transaction-route',
    path: '/type/transaction/:type',
    regex: RegExp(r'^/type/transaction/*$'),
  );

  static final recurringTransactions = RoutesConstant._(
    auth: true,
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
    typeTransaction,
    onboardingStepTheme,
    onboardingStepWallet,
    onboardingStepProfile,
    recurringTransactions,
  ];

  static RoutesConstant? match(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location));

  static bool needsAuthentication(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location))?.auth ??
      false;
}
