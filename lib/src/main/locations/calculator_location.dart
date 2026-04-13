import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/screens/calculator_screen.dart';

final class CalculatorLocation extends Location {
  @override
  String get path => AppRoutes.calculator.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(builder: (context) => CalculatorScreen());
}
