import 'package:trocado/main.dart';

import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';

void calculatorProvider() {
  provider.registerLazySingleton<CalculatorCubit>(
    CalculatorCubit.new,
    dispose: (cubit) => cubit.close(),
  );
}
