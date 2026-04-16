import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/screens/settings/settings_screen.dart';

final class SettingsLocation extends Location {
  @override
  String get path => AppRoutes.settings.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(
        const SettingsScreen(
          onEditProfile: _stub,
          onNotification: _stub,
          onSubscription: _stub,
        ),
      );

  static void _stub() {}
}
