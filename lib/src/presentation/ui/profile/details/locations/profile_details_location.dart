import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';

import 'package:trocado/src/presentation/ui/profile/name/locations/profile_name_location.dart';
import 'package:trocado/src/presentation/ui/profile/purge/locations/profile_purge_location.dart';
import 'package:trocado/src/presentation/ui/profile/details/screens/profile_details_screen.dart';
import 'package:trocado/src/presentation/ui/profile/password/locations/profile_password_location.dart';

final class ProfileDetailsLocation extends Location {
  @override
  String get path => AppRoutes.profile.path;

  @override
  LocationPageBuilder get pageBuilder => (context) => screenPage(
    ProfileDetailsScreen(
      onPurge: () => context.navigate(ProfilePurgeLocation()),
      onEditName: () => context.navigate(ProfileNameLocation()),
      onEditPassword: () => context.navigate(ProfilePasswordLocation()),
    ),
  );
}
