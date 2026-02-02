import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/domain/constants/routes_constant.dart';

import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/screens/calculator_screen.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/cubits/calculator/calculator_cubit.dart';

final class CalculatorLocation extends Location {
  @override
  String get path => RoutesConstant.calculator.path;

  @override
  LocationPageBuilder get pageBuilder => (context) {
    final cubit = context.get<CalculatorCubit>();

    return BottomSheetPage(builder: (_) => CalculatorScreen(cubit: cubit));
  };
}
