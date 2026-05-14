import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/partner/screens/partner_invite_screen.dart';
import 'package:trocado/src/presentation/ui/partner/locations/invite_qr_code_location.dart';

final class PartnerInviteLocation extends Location {
  @override
  String get path => AppRoutes.partnerInvite.path;

  @override
  LocationPageBuilder get pageBuilder => (context) => screenPage(
    PartnerInviteScreen(
      onGenerate: () => context.navigate(InviteQrCodeLocation()),
    ),
  );
}
