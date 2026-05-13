import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/partner/screens/partner_invite_screen.dart';

final class PartnerInviteLocation extends Location {
  @override
  String get path => AppRoutes.partnerInvite.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(const PartnerInviteScreen());
}
