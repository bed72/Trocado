import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/calculator/data/formatters/money_formater.dart';
import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';

void calculatorProvider() {
  provider
    ..registerFactory<DebounceAction>(DebounceAction.new)
    ..registerFactory<IMoneyFormatter>(MoneyFormatter.new)
    ..registerLazySingleton<CalculatorCubit>(
      () => CalculatorCubit(formatter: provider.get<IMoneyFormatter>()),
      dispose: (cubit) => cubit.close(),
    );
}
