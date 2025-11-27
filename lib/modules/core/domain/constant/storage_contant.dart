enum StorageConstant {
  image(key: 'user_image'),
  theme(key: 'is_dark_theme'),
  onboarding(key: 'is_the_first_time'),
  fingerprint(key: 'is_active_fingerprint'),
  notifications(key: 'is_active_notification');

  final String key;

  const StorageConstant({required this.key});
}
