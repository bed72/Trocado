import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/screens/expenses/screens/expenses_screen.dart';

final class ExpensesLocation extends Location {
  @override
  String get path => AppRoutes.expenses.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(const ExpensesScreen());
}
