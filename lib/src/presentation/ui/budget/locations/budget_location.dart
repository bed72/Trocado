import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/budget/screens/budget_screen.dart';
import 'package:trocado/src/presentation/ui/calculator/locations/calculator_location.dart';
import 'package:trocado/src/presentation/ui/date_range/locations/date_range_location.dart';

final class BudgetLocation extends Location {
  final int? id;

  const BudgetLocation({this.id});

  @override
  String get path => AppRoutes.budget.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        BudgetScreen(
          id: id,
          navigateToCalculator: (onValueConfirmed) => context.navigate(
            CalculatorLocation(onValueConfirmed: onValueConfirmed),
          ),
          navigateToDate:
              ({
                int? initialEndDate,
                int? initialStartDate,
                required onSelected,
              }) => context.navigate(
                DateRangeLocation(
                  onSelected: onSelected,
                  initialEndDate: initialEndDate,
                  initialStartDate: initialStartDate,
                  subtitle: 'Selecione o período do orçamento.',
                ),
              ),
        ),
      );
}
