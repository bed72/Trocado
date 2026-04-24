import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/expenses/screens/expenses_filter_screen.dart';
import 'package:trocado/src/presentation/ui/date_range/locations/date_range_location.dart';

final class ExpensesFilterLocation extends Location {
  final ExpenseFilterModel initialFilter;

  const ExpensesFilterLocation({required this.initialFilter});

  @override
  String get path => AppRoutes.expensesFilter.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        ExpensesFilterScreen(
          initialFilter: initialFilter,
          navigateToDateRange:
              ({
                int? initialEndDate,
                int? initialStartDate,
                required onSelected,
              }) => context.navigate(
                DateRangeLocation(
                  onSelected: onSelected,
                  initialEndDate: initialEndDate,
                  initialStartDate: initialStartDate,
                  subtitle: 'Selecione o período a filtrar.',
                ),
              ),
        ),
      );
}
