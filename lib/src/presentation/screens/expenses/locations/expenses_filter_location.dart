import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/screens/expenses/screens/expenses_filter_screen.dart';

final class ExpensesFilterLocation extends Location {
  @override
  String get path => AppRoutes.expensesFilter.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(builder: (_) => const ExpensesFilterScreen());
}
