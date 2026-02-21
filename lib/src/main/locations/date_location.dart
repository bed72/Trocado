import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/screens/date_screen.dart';
import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';

final class DateLocation extends Location {
  @override
  String get path => AppRoutes.date.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(builder: (_) => DateScreen());
}
