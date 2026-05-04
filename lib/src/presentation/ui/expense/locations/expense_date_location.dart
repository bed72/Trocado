import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/ui/expense/screens/expense_date_screen.dart';

final class ExpenseDateLocation extends Location {
  final int? id;

  const ExpenseDateLocation({this.id});

  @override
  String get path => AppRoutes.expenseDate.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(builder: (_) => ExpenseDateScreen(id: id));
}
