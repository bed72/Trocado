import 'package:trocado/main.dart';

import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';
import 'package:trocado/modules/calculator/data/repositories/calculator_repository.dart';
import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

void calculatorProvider() {
  provider
    ..registerFactory<ICalculatorRepository>(CalculatorRepository.new)
    ..registerLazySingleton<CalculatorCubit>(
      () => CalculatorCubit(repository: provider.get<ICalculatorRepository>()),
    );
}
