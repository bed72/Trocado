enum ThemeModeEnum {
  dark('dark'),
  light('light'),
  system('system');

  const ThemeModeEnum(this.value);

  final String value;

  static ThemeModeEnum fromString(String? value) => switch (value) {
    'dark' => .dark,
    'light' => .light,
    'system' => .system,
    _ => .system,
  };
}
