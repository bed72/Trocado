import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/screens/expense_screen.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/screens/expense/locations/expense_date_location.dart';

final class ExpenseLocation extends Location {
  final int? id;

  const ExpenseLocation({this.id});

  @override
  String get path => AppRoutes.expense.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        ExpenseScreen(
          navigateToDate: () => context.navigate(ExpenseDateLocation()),
        ),
      );
}
