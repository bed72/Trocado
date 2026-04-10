import 'package:get_it/get_it.dart';

import 'package:trocado/src/application/services/money_service.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';

import 'package:trocado/src/presentation/mapper/expense_presentation_mapper.dart';

final sl = GetIt.instance;

void ensureInitialized() {
  sl.registerLazySingleton<ILoggerClient>(LoggerClient.new);

  // Services
  sl.registerLazySingleton<IMoneyService>(MoneyService.new);

  // Data Sources (Infrastructure)

  // Mappers (Data)
  sl
    ..registerFactory(ExpenseModelToPresentationMapper.new)
    ..registerFactory(ExpenseStateToModelMapper.new);
}
