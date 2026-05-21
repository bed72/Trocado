import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart';

final class CoupleScanLocation extends Location {
  @override
  String get path => AppRoutes.coupleScan.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(const CoupleScanScreen());
}
