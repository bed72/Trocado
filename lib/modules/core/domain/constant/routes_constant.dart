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

  static final other = RoutesConstant._(
    auth: true,
    path: '/other',
    name: 'other-route',
    regex: RegExp(r'^/other$'),
  );

  static final report = RoutesConstant._(
    auth: true,
    path: '/report',
    name: 'report-route',
    regex: RegExp(r'^/report$'),
  );

  static final settings = RoutesConstant._(
    auth: true,
    path: '/settings',
    name: 'settings-route',
    regex: RegExp(r'^/settings$'),
  );

  static final transaction = RoutesConstant._(
    auth: true,
    path: '/transaction',
    name: 'transaction-route',
    regex: RegExp(r'^/transaction$'),
  );

  static final allTransaction = RoutesConstant._(
    auth: true,
    path: '/all/transaction',
    name: 'all-transaction-route',
    regex: RegExp(r'^/all/transaction$'),
  );

  static final typeTransaction = RoutesConstant._(
    auth: true,
    name: 'type-transaction-route',
    path: '/type/transaction/:type',
    regex: RegExp(r'^/type/transaction/*$'),
  );

  static final _all = [
    core,
    home,
    report,
    splash,
    settings,
    transaction,
    allTransaction,
    typeTransaction,
  ];

  static RoutesConstant? match(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location));

  static bool needsAuthentication(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location))?.auth ??
      false;
}
