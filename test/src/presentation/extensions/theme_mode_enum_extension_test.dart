import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';
import 'package:trocado/src/presentation/extensions/theme_mode_enum_extension.dart';

void main() {
  group('icon', () {
    test('light returns Icons.light_mode_outlined', () {
      expect(ThemeModeEnum.light.icon, Icons.light_mode_outlined);
    });

    test('dark returns Icons.dark_mode_outlined', () {
      expect(ThemeModeEnum.dark.icon, Icons.dark_mode_outlined);
    });

    test('system returns Icons.brightness_auto_outlined', () {
      expect(ThemeModeEnum.system.icon, Icons.brightness_auto_outlined);
    });
  });

  group('themeMode', () {
    test('light returns ThemeMode.light', () {
      expect(ThemeModeEnum.light.themeMode, ThemeMode.light);
    });

    test('dark returns ThemeMode.dark', () {
      expect(ThemeModeEnum.dark.themeMode, ThemeMode.dark);
    });

    test('system returns ThemeMode.system', () {
      expect(ThemeModeEnum.system.themeMode, ThemeMode.system);
    });
  });
}
