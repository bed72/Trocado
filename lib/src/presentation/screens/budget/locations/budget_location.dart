import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/calculator/calculator_location.dart';

import 'package:trocado/src/presentation/screens/budget/screens/budget_screen.dart';
import 'package:trocado/src/presentation/screens/budget/locations/budget_date_location.dart';

final class BudgetLocation extends Location {
  @override
  String get path => AppRoutes.budget.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        BudgetScreen(
          navigateToDate: () => context.navigate(BudgetDateLocation()),
          navigateToCalculator: (onValueConfirmed) => context.navigate(
            CalculatorLocation(onValueConfirmed: onValueConfirmed),
          ),
        ),
      );
}
