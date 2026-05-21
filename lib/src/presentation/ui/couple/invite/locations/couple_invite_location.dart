import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/couple/invite/screens/couple_invite_screen.dart';
import 'package:trocado/src/presentation/ui/couple/invite/locations/invite_qr_code_location.dart';
import 'package:trocado/src/presentation/ui/couple/scan/locations/couple_scan_location.dart';

final class CoupleInviteLocation extends Location {
  @override
  String get path => AppRoutes.coupleInvite.path;

  @override
  LocationPageBuilder get pageBuilder => (context) => screenPage(
    CoupleInviteScreen(
      onScan: () => context.navigate(CoupleScanLocation()),
      onGenerate: () => context.navigate(InviteQrCodeLocation()),
    ),
  );
}
