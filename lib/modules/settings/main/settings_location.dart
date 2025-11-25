import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/settings/presentation/dtos/settings_dto.dart';

import 'package:trocado/modules/settings/presentation/screens/settings_screen.dart';

final class SettingsLocation extends Location {
  @override
  String get path => RoutesConstant.settings.path;

  @override
  LocationBuilder? get builder =>
      (_) =>
          ConsumerManyBuilder<
            ThemeNotifier,
            NotificationNotifier,
            FingerprintNotifier
          >(
            builder: (context, theme, notification, fingerprint) =>
                SettingsScreen(
                  dto: SettingsDto.build(
                    context: context,
                    isDark: theme.isDark,
                    onToggleThemes: theme.toggle,
                    fingerprintEnabled: fingerprint.enabled,
                    onToggleFingerprint: fingerprint.toggle,
                    notificationsEnabled: notification.enabled,
                    onToggleNotifications: notification.toggle,
                  ),
                ),
          );
}
