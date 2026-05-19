enum StorageKey {
  themeMode('theme_mode'),
  accessToken('access_token'),
  refreshToken('refresh_token');

  const StorageKey(this.value);

  final String value;
}
