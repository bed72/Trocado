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
      tintedDisabledControls: true,
      inputDecoratorIsFilled: true,
      navigationRailUseIndicator: true,

      buttonMinSize: Size(48.0, 48.0),

      elevatedButtonRadius: 16.0,
      elevatedButtonElevation: 0.0,
      elevatedButtonSchemeColor: .onPrimary,
      elevatedButtonSecondarySchemeColor: .primary,
      elevatedButtonTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 14.0,
          fontWeight: .w600,
          color: darkColorScheme.inverseSurface,
        ),
      ),

      outlinedButtonRadius: 16.0,
      outlinedButtonSchemeColor: .primary,
      outlinedButtonOutlineSchemeColor: .primary,
      outlinedButtonTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 14.0,
          fontWeight: .w600,
          color: darkColorScheme.inverseSurface,
        ),
      ),

      inputDecoratorBorderType: FlexInputBorderType.outline,
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
      inputDecoratorIsFilled: true,
      tintedDisabledControls: true,
      navigationRailUseIndicator: true,

      buttonMinSize: Size(48.0, 48.0),

      elevatedButtonRadius: 16.0,
      elevatedButtonElevation: 0.0,
      elevatedButtonSchemeColor: .primary,
      elevatedButtonSecondarySchemeColor: .onPrimary,
      elevatedButtonTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 14.0,
          fontWeight: .w600,
          color: darkColorScheme.inverseSurface,
        ),
      ),

      outlinedButtonRadius: 16.0,
      outlinedButtonSchemeColor: .primary,
      outlinedButtonOutlineSchemeColor: .primary,
      outlinedButtonTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 14.0,
          fontWeight: .w600,
          color: darkColorScheme.inverseSurface,
        ),
      ),

      inputDecoratorBorderType: .outline,
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
