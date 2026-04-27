abstract final class AppConfig {
  static const url = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.1.72:8080',
  );
}
