import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

@immutable
final class RoutesConstant {
  final bool auth;
  final String path;
  final String name;
  final RegExp regex;
  final bool hideBottomBar;

  const RoutesConstant._({
    required this.auth,
    required this.path,
    required this.name,
    required this.regex,
    required this.hideBottomBar,
  });

  static final core = RoutesConstant._(
    auth: false,
    path: '/core',
    hideBottomBar: true,
    name: 'core-route',
    regex: RegExp(r'/core'),
  );

  static final splash = RoutesConstant._(
    auth: false,
    path: '/splash',
    hideBottomBar: true,
    name: 'splash-route',
    regex: RegExp(r'/splash'),
  );

  static final home = RoutesConstant._(
    auth: true,
    path: '/home',
    name: 'home-route',
    hideBottomBar: false,
    regex: RegExp(r'^/$'),
  );

  static final other = RoutesConstant._(
    auth: true,
    path: '/other',
    name: 'other-route',
    hideBottomBar: true,
    regex: RegExp(r'^/other$'),
  );

  static final settings = RoutesConstant._(
    auth: true,
    path: '/settings',
    hideBottomBar: false,
    name: 'settings-route',
    regex: RegExp(r'^/settings'),
  );

  static final transaction = RoutesConstant._(
    auth: true,
    path: '/transaction',
    hideBottomBar: false,
    name: 'transaction-route',
    regex: RegExp(r'^/transaction'),
  );

  static final typeTransaction = RoutesConstant._(
    auth: true,
    hideBottomBar: true,
    name: 'type-transaction-route',
    path: '/type/transaction/:type',
    regex: RegExp(r'^/type/transaction/*$'),
  );

  static final _all = [
    core,
    home,
    splash,
    settings,
    transaction,
    typeTransaction,
  ];

  static List<RoutesConstant> get hideBottomBarTo =>
      _all.where((route) => route.hideBottomBar == true).toList();

  static RoutesConstant? match(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location));

  static bool needsAuthentication(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location))?.auth ??
      false;
}
