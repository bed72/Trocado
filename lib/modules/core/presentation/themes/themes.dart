import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:trocado/modules/core/presentation/themes/colors/color_theme.dart';
import 'package:trocado/modules/core/presentation/themes/radius/radius_theme.dart';

abstract final class Themes {
  static ThemeData light = FlexThemeData.light(
    scheme: FlexScheme.money,
    colorScheme: lightColorScheme,
    extensions: <ThemeExtension<dynamic>>[radius],
    subThemesData: const FlexSubThemesData(
      alignedDropdown: true,
      interactionEffects: true,
      useM2StyleDividerInM3: false,
      tintedDisabledControls: true,
      inputDecoratorIsFilled: true,
      navigationRailUseIndicator: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),

    appBarElevation: 0.0,
    bottomAppBarElevation: 0.0,
    appBarBackground: lightColorScheme.surfaceContainerLowest,
    scaffoldBackground: lightColorScheme.surfaceContainerLowest,
  );

  static ThemeData dark = FlexThemeData.dark(
    scheme: FlexScheme.money,
    colorScheme: darkColorScheme,
    extensions: <ThemeExtension<dynamic>>[radius],
    subThemesData: const FlexSubThemesData(
      blendOnColors: true,
      alignedDropdown: true,
      interactionEffects: true,
      useM2StyleDividerInM3: false,
      inputDecoratorIsFilled: true,
      tintedDisabledControls: true,
      navigationRailUseIndicator: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),

    appBarElevation: 0.0,
    bottomAppBarElevation: 0.0,
    appBarBackground: darkColorScheme.surfaceContainerLowest,
    scaffoldBackground: darkColorScheme.surfaceContainerLowest,
  );
}
