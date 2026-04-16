import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/screens/budget/budget_screen.dart';

final class BudgetLocation extends Location {
  @override
  String get path => AppRoutes.expense.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(
        BudgetScreen(navigateToDate: () {}, navigateToCalculator: () {}),
      );
}
