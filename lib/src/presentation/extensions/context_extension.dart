import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/presentation/themes/radius/radius_theme.dart';

extension BuildContextColorExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

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

extension BuildContextProvideExtension on BuildContext {
  T get<T extends Object>({
    dynamic param1,
    dynamic param2,
    Type? type,
    String? instanceName,
  }) => GetIt.instance.get(
    type: type,
    param1: param1,
    param2: param2,
    instanceName: instanceName,
  );
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

  Future<T?> navigate<T extends Object?>(
    Location to, {
    bool? replace,
    bool? clearStack,
    bool root = false,
  }) => DuckRouter.of(
    this,
  ).navigate<T>(to: to, root: root, replace: replace, clearStack: clearStack);
}
