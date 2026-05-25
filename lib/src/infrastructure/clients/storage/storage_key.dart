enum StorageKey {
  themeMode('theme_mode'),
  accessToken('access_token'),
  refreshToken('refresh_token'),
  chatSessionId('chat_session_id');

  const StorageKey(this.value);

  final String value;
}
