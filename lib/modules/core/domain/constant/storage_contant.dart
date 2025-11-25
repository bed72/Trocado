enum StorageConstant {
  theme(key: 'is_dark_theme'),
  fingerprint(key: 'is_active_fingerprint'),
  notifications(key: 'is_active_notification');

  final String key;

  const StorageConstant({required this.key});
}
