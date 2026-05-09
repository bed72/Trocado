import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/profile/delete/screens/profile_delete_screen.dart';

final class ProfileDeleteLocation extends Location {
  @override
  String get path => AppRoutes.profileDelete.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(const ProfileDeleteScreen());
}
