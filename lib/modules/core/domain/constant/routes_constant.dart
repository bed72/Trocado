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

  static final exit = RoutesConstant._(
    path: '/exit',
    name: 'exit-route',
    regex: RegExp(r'/exit$'),
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

  static final _all = [exit, home, splash, calculator, transactions];

  static RoutesConstant? match(String location) =>
      _all.firstWhereOrNull((route) => route.regex.hasMatch(location));
}
