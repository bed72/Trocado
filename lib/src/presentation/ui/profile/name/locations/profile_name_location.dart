import 'package:flutter/widgets.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/profile/name/screens/profile_name_screen.dart';

final class ProfileNameLocation extends Location {
  final VoidCallback onSuccess;

  const ProfileNameLocation({required this.onSuccess});

  @override
  String get path => AppRoutes.profileName.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(ProfileNameScreen(onSuccess: onSuccess));
}
