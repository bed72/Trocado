import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/screens/budget/screens/budget_date_screen.dart';

final class BudgetDateLocation extends Location {
  @override
  String get path => AppRoutes.budgetDate.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(builder: (_) => const BudgetDateWidget());
}
