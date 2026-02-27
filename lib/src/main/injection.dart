import 'package:get_it/get_it.dart';

import 'package:trocado/src/data/mapper/budget_mapper.dart';
import 'package:trocado/src/data/mapper/expense_mapper.dart';

import 'package:trocado/src/data/services/money_service.dart';

import 'package:trocado/src/data/repositories/budget_repository.dart';
import 'package:trocado/src/data/repositories/expense_repository.dart';

import 'package:trocado/src/data/datasources/interface_budget_data_source.dart';
import 'package:trocado/src/data/datasources/interface_expense_data_source.dart';

import 'package:trocado/src/domain/services/interface_money_service.dart';
import 'package:trocado/src/domain/use_cases/get_budget_summary_use_case.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/mapper/expense_presentation_mapper.dart';

import 'package:trocado/src/presentation/bloc/budget/budget_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_bloc.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/database/database_client.dart';
import 'package:trocado/src/infrastructure/datasources/local/budget_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/local/expense_data_source.dart';

final sl = GetIt.instance;

Future<void> ensureInitialized() async {
  _dependencies();

  final database = sl.get<IDatabaseClient>();
  await database.ensureInitialized();
}

void _dependencies() {
  sl
    ..registerLazySingleton<ILoggerClient>(LoggerClient.new)
    ..registerLazySingleton<IDatabaseClient>(
      () => DatabaseClient(client: sl()),
    );

  // Services
  sl.registerLazySingleton<IMoneyService>(MoneyService.new);

  // Mappers
  sl
    ..registerFactory(BudgetModelToEntityMapper.new)
    ..registerFactory(BudgetEntityToModelMapper.new)
    ..registerFactory(ExpenseModelToEntityMapper.new)
    ..registerFactory(ExpenseEntityToModelMapper.new)
    ..registerFactory(ExpenseModelToPresentationMapper.new)
    ..registerFactory(ExpenseStateToModelMapper.new);

  // Data Sources
  sl
    ..registerLazySingleton<IExpenseDataSource>(
      () => ExpenseDataSource(client: sl()),
    )
    ..registerLazySingleton<IBudgetDataSource>(
      () => BudgetDataSource(client: sl()),
    );

  // Repositories
  sl
    ..registerLazySingleton<IExpenseRepository>(
      () => ExpenseRepository(
        dataSource: sl(),
        expenseToModelMapper: sl(),
        expenseToEntityMapper: sl(),
      ),
    )
    ..registerLazySingleton<IBudgetRepository>(
      () => BudgetRepository(
        dataSource: sl(),
        entityToModelMapper: sl(),
        modelToEntityMapper: sl(),
      ),
    );

  // Use Cases
  sl.registerFactory(() => GetBudgetSummaryUseCase(repository: sl()));

  // BLocs
  sl
    ..registerFactory(
      () => ExpenseListBloc(service: sl(), mapper: sl(), repository: sl()),
    )
    ..registerFactory(
      () => ExpenseFormBloc(service: sl(), repository: sl(), mapper: sl()),
    )
    ..registerFactory(() => BudgetBloc(repository: sl(), useCase: sl()));
}
