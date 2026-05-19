import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';

void main() {
  group('ThemeModeEnum.fromString', () {
    test('returns light for "light"', () {
      expect(ThemeModeEnum.fromString('light'), ThemeModeEnum.light);
    });

    test('returns dark for "dark"', () {
      expect(ThemeModeEnum.fromString('dark'), ThemeModeEnum.dark);
    });

    test('returns system for "system"', () {
      expect(ThemeModeEnum.fromString('system'), ThemeModeEnum.system);
    });

    test('returns system for null', () {
      expect(ThemeModeEnum.fromString(null), ThemeModeEnum.system);
    });

    test('returns system for unknown value', () {
      expect(ThemeModeEnum.fromString('gibberish'), ThemeModeEnum.system);
    });

    test('returns system for empty string', () {
      expect(ThemeModeEnum.fromString(''), ThemeModeEnum.system);
    });
  });

  group('ThemeModeEnum.value', () {
    test('light has value "light"', () {
      expect(ThemeModeEnum.light.value, 'light');
    });

    test('dark has value "dark"', () {
      expect(ThemeModeEnum.dark.value, 'dark');
    });

    test('system has value "system"', () {
      expect(ThemeModeEnum.system.value, 'system');
    });
  });
}
