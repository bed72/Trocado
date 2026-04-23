import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/date_range/locations/date_range_location.dart';

import 'package:trocado/src/presentation/screens/expenses/screens/expenses_filter_screen.dart';

final class ExpensesFilterLocation extends Location {
  @override
  String get path => AppRoutes.expensesFilter.path;

  @override
  LocationPageBuilder get pageBuilder => (context) => screenPage(
    ExpensesFilterScreen(
      navigateToCustomRange:
          ({int? initialStartDate, int? initialEndDate, required onSelected}) =>
              context.navigate(
                DateRangeLocation(
                  onSelected: onSelected,
                  initialStartDate: initialStartDate,
                  initialEndDate: initialEndDate,
                  subtitle: 'Selecione o período a filtrar.',
                ),
              ),
    ),
  );
}
