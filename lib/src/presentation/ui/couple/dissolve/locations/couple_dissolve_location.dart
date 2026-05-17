import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/screens/couple_dissolve_screen.dart';

final class CoupleDissolveLocation extends Location {
  @override
  String get path => AppRoutes.coupleDissolve.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(const CoupleDissolveScreen());
}
