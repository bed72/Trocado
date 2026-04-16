import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/screens/settings/settings_screen.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/sign_in_location.dart';

final class SettingsLocation extends Location {
  @override
  String get path => AppRoutes.settings.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        SettingsScreen(
          onEditProfile: () {},
          onNotification: () {},
          onSubscription: () {},
          onSignIn: () {
            context.root();
            context.navigate(SignInLocation(), root: true, replace: true);
          },
        ),
      );
}
