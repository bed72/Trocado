import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/settings/screens/settings_screen.dart';
import 'package:trocado/src/presentation/ui/partner/locations/partner_invite_location.dart';
import 'package:trocado/src/presentation/ui/profile/details/locations/profile_details_location.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_in/locations/sign_in_location.dart';

final class SettingsLocation extends Location {
  @override
  String get path => AppRoutes.settings.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        SettingsScreen(
          onNotification: () {},
          onSubscription: () {},
          onEditProfile: () => context.navigate(ProfileDetailsLocation()),
          onInvitePartner: () => context.navigate(PartnerInviteLocation()),
          onSignIn: () =>
              context.clear(SignInLocation(), root: true, replace: true),
        ),
      );
}
