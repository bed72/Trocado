import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart';

final class CoupleScanConfirmLocation extends Location {
  final String code;
  final InviteLookupModel lookup;

  const CoupleScanConfirmLocation({required this.code, required this.lookup});

  @override
  String get path => AppRoutes.coupleScanConfirm.path;

  @override
  LocationPageBuilder get pageBuilder => (context) => screenPage(
    CoupleScanConfirmScreen(code: code, lookup: lookup),
  );
}
