import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/presentation/themes/radius/radius_theme.dart';

extension BuildContextExtension on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  double get bottom => MediaQuery.of(this).viewInsets.bottom;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get typography => Theme.of(this).textTheme;
  CornerRadiusToken get radius =>
      Theme.of(this).extension<CornerRadiusToken>()!;

  T get<T>() => read<T>();

  bool canPop() => Navigator.canPop(this);

  void root() => DuckRouter.of(this).root();

  void exit<T extends Object?>([T? result]) =>
      DuckRouter.of(this).exit<T>(result);

  void pop<T extends Object?>([T? result]) =>
      DuckRouter.of(this).pop<T>(result);

  void popUntil(LocationPredicate predicate) =>
      DuckRouter.of(this).popUntil(predicate);

  Future<T?> navigate<T extends Object?>(
    Location to, {
    bool? replace,
    bool? clearStack,
    bool root = false,
  }) => DuckRouter.of(
    this,
  ).navigate<T>(to: to, root: root, replace: replace, clearStack: clearStack);
}
