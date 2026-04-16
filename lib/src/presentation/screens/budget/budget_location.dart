import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/main/locations/calculator_location.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/screens/budget/budget_screen.dart';
import 'package:trocado/src/presentation/screens/budget/budget_date_location.dart';

final class BudgetLocation extends Location {
  @override
  String get path => AppRoutes.budget.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        BudgetScreen(
          navigateToDate: () => context.navigate(BudgetDateLocation()),
          navigateToCalculator: () => context.navigate(CalculatorLocation()),
        ),
      );
}
