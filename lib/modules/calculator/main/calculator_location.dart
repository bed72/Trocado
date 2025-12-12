import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/calculator/presentation/screens/calculator_screen.dart';
import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

final class CalculatorLocation extends Location {
  @override
  String get path => RoutesConstant.calculator.path;

  @override
  LocationPageBuilder get pageBuilder => (context) {
    final calculator = context.get<ICalculatorRepository>();

    return BottomSheetPage(
      builder: (_) => CalculatorScreen(evaluate: calculator.call),
    );
  };
}
