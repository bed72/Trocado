import 'package:flutter/material.dart';

import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';

extension ThemeModeEnumExtension on ThemeModeEnum {
  IconData get icon => switch (this) {
    .dark => Icons.dark_mode_outlined,
    .light => Icons.light_mode_outlined,
    .system => Icons.brightness_6_outlined,
  };

  ThemeMode get themeMode => switch (this) {
    .dark => ThemeMode.dark,
    .light => ThemeMode.light,
    .system => ThemeMode.system,
  };
}
