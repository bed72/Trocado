abstract final class AppConfig {
  static const url = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8001',
  );
}
