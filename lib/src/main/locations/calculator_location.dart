import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/screens/calculator_screen.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

final class CalculatorLocation extends Location {
  @override
  String get path => RoutesConstant.calculator.path;

  @override
  LocationPageBuilder get pageBuilder => (context) {
    final cubit = context.get<TransactionCubit>();

    return BottomSheetPage(builder: (_) => CalculatorScreen(cubit: cubit));
  };
}
