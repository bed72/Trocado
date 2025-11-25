import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/settings/presentation/screens/settings_screen.dart';

final class SettingsLocation extends Location {
  @override
  String get path => RoutesConstant.settings.path;

  @override
  LocationBuilder? get builder =>
      (context) => ConsumersBuilder<ThemeNotifier, NotificationNotifier>(
        builder: (_, theme, notification) => SettingsScreen(
          isDark: theme.isDark,
          onToggleThemes: theme.toggle,
          onToggleNotifications: notification.toggle,
          notificationsEnabled: notification.enabled,
        ),
      );
}
