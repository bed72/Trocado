import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/expenses/screens/expenses_screen.dart';
import 'package:trocado/src/presentation/ui/expenses/locations/expenses_filter_location.dart';

final class ExpensesLocation extends Location {
  @override
  String get path => AppRoutes.expenses.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        ExpensesScreen(
          navigateToFilter: () => context.navigate(ExpensesFilterLocation()),
        ),
      );
}
