import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/profile/screens/profile_screen.dart';

final class ProfileLocation extends Location {
  @override
  String get path => AppRoutes.profile.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(const ProfileScreen());
}
