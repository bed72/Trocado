import 'package:flutter/widgets.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/profile/password/screens/profile_password_screen.dart';

final class ProfilePasswordLocation extends Location {
  final VoidCallback onSuccess;

  const ProfilePasswordLocation({required this.onSuccess});

  @override
  String get path => AppRoutes.profilePassword.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(ProfilePasswordScreen(onSuccess: onSuccess));
}
