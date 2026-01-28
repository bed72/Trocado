import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';

void calculatorProvider() {
  i.registerLazySingleton<CalculatorCubit>(
    () => CalculatorCubit(formatter: i.get<IMoneyFormatter>()),
    dispose: (cubit) => cubit.close(),
  );
}
