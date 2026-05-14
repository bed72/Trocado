import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/partner/screens/invite_qr_code_screen.dart';

final class InviteQrCodeLocation extends Location {
  @override
  String get path => AppRoutes.partnerInviteQrCode.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(const InviteQrCodeScreen());
}
