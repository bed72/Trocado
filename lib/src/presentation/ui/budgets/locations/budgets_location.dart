import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/budgets/screens/budgets_screen.dart';

final class BudgetsLocation extends Location {
  @override
  String get path => AppRoutes.budgets.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(const BudgetsScreen());
}
