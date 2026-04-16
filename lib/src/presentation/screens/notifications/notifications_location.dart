import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/screens/notifications/notifications_screen.dart';

final class NotificationsLocation extends Location {
  @override
  String get path => AppRoutes.notifications.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(const NotificationsScreen());
}
