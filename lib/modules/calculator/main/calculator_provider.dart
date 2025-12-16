import 'package:trocado/main.dart';

import 'package:trocado/modules/calculator/presentation/stores/calculator_store.dart';

import 'package:trocado/modules/calculator/data/repositories/calculator_repository.dart';

import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

void providesCalculator() {
  provider
    ..registerFactory<ICalculatorRepository>(CalculatorRepository.new)
    ..registerFactory<CalculatorStore>(
      () => CalculatorStore(repository: provider.get<ICalculatorRepository>()),
    );
}
