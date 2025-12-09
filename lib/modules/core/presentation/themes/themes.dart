import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'package:trocado/modules/core/presentation/themes/colors/color_theme.dart';
import 'package:trocado/modules/core/presentation/themes/radius/radius_theme.dart';

abstract final class Themes {
  static ThemeData light = FlexThemeData.light(
    fontFamily: 'Inter',
    scheme: FlexScheme.money,
    colorScheme: lightColorScheme,
    extensions: <ThemeExtension<dynamic>>[radius],
    subThemesData: FlexSubThemesData(
      alignedDropdown: true,
      interactionEffects: true,
      useM2StyleDividerInM3: false,
      useMaterial3Typography: true,
      tintedDisabledControls: true,
      inputDecoratorIsFilled: true,
      navigationRailUseIndicator: true,

      buttonMinSize: Size(54.0, 54.0),

      elevatedButtonRadius: 16.0,
      elevatedButtonElevation: 0.0,
      elevatedButtonSchemeColor: .onPrimary,
      elevatedButtonSecondarySchemeColor: .primary,
      elevatedButtonTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 14.0, fontWeight: .w500),
      ),

      outlinedButtonRadius: 16.0,
      outlinedButtonTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 14.0, fontWeight: .w500),
      ),

      inputDecoratorRadius: 16.0,
      inputDecoratorIsDense: true,
      inputDecoratorBorderType: .outline,

      inputDecoratorContentPadding: const .symmetric(
        vertical: 14.0,
        horizontal: 0.0,
      ),
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    appBarElevation: 0.0,
    bottomAppBarElevation: 0.0,
    surfaceTint: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    appBarBackground: lightColorScheme.surfaceContainerLowest,
    scaffoldBackground: lightColorScheme.surfaceContainerLowest,
  );

  static ThemeData dark = FlexThemeData.dark(
    fontFamily: 'Inter',
    scheme: FlexScheme.money,
    colorScheme: darkColorScheme,
    extensions: <ThemeExtension<dynamic>>[radius],
    subThemesData: FlexSubThemesData(
      blendOnColors: true,
      alignedDropdown: true,
      interactionEffects: true,
      useM2StyleDividerInM3: false,
      useMaterial3Typography: true,
      inputDecoratorIsFilled: true,
      tintedDisabledControls: true,
      navigationRailUseIndicator: true,

      buttonMinSize: Size(54.0, 54.0),

      elevatedButtonRadius: 16.0,
      elevatedButtonElevation: 0.0,
      elevatedButtonTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 14.0, fontWeight: .w500),
      ),

      outlinedButtonRadius: 16.0,
      outlinedButtonTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 14.0, fontWeight: .w500),
      ),

      inputDecoratorRadius: 16.0,
      inputDecoratorIsDense: true,
      inputDecoratorBorderType: .outline,
      inputDecoratorContentPadding: const .symmetric(
        vertical: 14.0,
        horizontal: 0.0,
      ),
    ),

    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    appBarElevation: 0.0,
    bottomAppBarElevation: 0.0,
    surfaceTint: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    appBarBackground: darkColorScheme.surfaceContainerLowest,
    scaffoldBackground: darkColorScheme.surfaceContainerLowest,
  );
}
