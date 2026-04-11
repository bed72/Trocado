enum StorageKey {
  accessToken('access_token'),
  refreshToken('refresh_token');

  const StorageKey(this.value);

  final String value;
}
