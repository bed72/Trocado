import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/presentation/themes/radius/radius_theme.dart';

extension BuildContextColorExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == .dark;

  ColorScheme get colors => Theme.of(this).colorScheme;
}

extension BuildContextCommonExtension on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  double get bottom => MediaQuery.of(this).viewInsets.bottom;

  TextTheme get typography => Theme.of(this).textTheme;
  CornerRadiusToken get radius =>
      Theme.of(this).extension<CornerRadiusToken>()!;
}

extension BuildContextNavigatinExtension on BuildContext {
  bool canPop() => Navigator.canPop(this);

  void root() => DuckRouter.of(this).root();

  void exit<T extends Object?>([T? result]) =>
      DuckRouter.of(this).exit<T>(result);

  void pop<T extends Object?>([T? result]) =>
      DuckRouter.of(this).pop<T>(result);

  void popUntil(LocationPredicate predicate) =>
      DuckRouter.of(this).popUntil(predicate);

  void clear(
    Location to, {
    bool? replace,
    bool? clearStack,
    bool root = false,
  }) {
    this.root();
    navigate(to, root: root, replace: replace, clearStack: clearStack);
  }

  Future<T?> navigate<T extends Object?>(
    Location to, {
    bool? replace,
    bool? clearStack,
    bool root = false,
  }) => DuckRouter.of(
    this,
  ).navigate<T>(to: to, root: root, replace: replace, clearStack: clearStack);
}
