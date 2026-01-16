import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';
import 'package:trocado/modules/calculator/presentation/screens/calculator_screen.dart';

final class CalculatorLocation extends Location {
  @override
  String get path => RoutesConstant.calculator.path;

  @override
  LocationPageBuilder get pageBuilder => (context) {
    final cubit = context.get<CalculatorCubit>();

    return BottomSheetPage(builder: (_) => CalculatorScreen(cubit: cubit));
  };
}
