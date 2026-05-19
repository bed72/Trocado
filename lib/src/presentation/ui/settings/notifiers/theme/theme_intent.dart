import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';

sealed class ThemeIntent {
  const ThemeIntent();
}

final class ToggleTheme extends ThemeIntent {
  const ToggleTheme();
}

final class SetTheme extends ThemeIntent {
  final ThemeModeEnum mode;

  const SetTheme(this.mode);
}
