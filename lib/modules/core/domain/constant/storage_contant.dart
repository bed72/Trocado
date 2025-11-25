enum StorageConstant {
  theme(key: 'is_dark_theme'),
  notifications(key: 'is_active_notification');

  final String key;

  const StorageConstant({required this.key});
}
