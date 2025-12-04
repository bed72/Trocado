import 'package:duck_router/duck_router.dart';
import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

final class SettingsLocation extends Location {
  @override
  String get path => RoutesConstant.settings.path;

  @override
  LocationBuilder? get builder =>
      (_) => SizedBox();
  // ConsumerManyBuilder<
  //   ThemeNotifier,
  //   NotificationNotifier,
  //   FingerprintNotifier
  // >(
  //   builder: (context, theme, notification, fingerprint) =>
  //       SettingsScreen(
  //         dto: SettingsDto.build(
  //           context: context,
  //           isDark: theme.isDark,
  //           onToggleThemes: theme.toggle,
  //           fingerprintEnabled: fingerprint.enabled,
  //           onToggleFingerprint: fingerprint.toggle,
  //           notificationsEnabled: notification.enabled,
  //           onToggleNotifications: notification.toggle,
  //         ),
  //       ),
  // );
}
