import 'package:get_it/get_it.dart';

import 'package:trocado/src/data/mapper/expense_mapper.dart';
import 'package:trocado/src/data/mapper/budget_mapper.dart';
import 'package:trocado/src/data/services/money_service.dart';
import 'package:trocado/src/data/repositories/expense_repository.dart';
import 'package:trocado/src/data/repositories/budget_repository.dart';

import 'package:trocado/src/domain/services/interface_money_repository.dart';
import 'package:trocado/src/domain/usecases/get_budget_summary.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/data/datasources/interface_expense_data_source.dart';
import 'package:trocado/src/data/datasources/interface_budget_data_source.dart';
import 'package:trocado/src/infrastructure/clients/database/database_client.dart';
import 'package:trocado/src/infrastructure/datasources/local/expense_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/local/budget_data_source.dart';

import 'package:trocado/src/presentation/mapper/expense_presentation_mapper.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:trocado/src/presentation/bloc/budget/budget_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Infrastructure
  sl.registerLazySingleton<ILoggerClient>(() => LoggerClient());
  sl.registerLazySingleton<IDatabaseClient>(
    () => DatabaseClient(client: sl()),
  );

  // Services
  sl.registerLazySingleton<IMoneyService>(() => MoneyService());

  // Mappers
  sl.registerFactory(() => ExpenseEntityToModelMapper());
  sl.registerFactory(() => ExpenseModelToEntityMapper());
  sl.registerFactory(() => ExpensePresentationToModelMapper());
  sl.registerFactory(() => BudgetEntityToModelMapper());
  sl.registerFactory(() => BudgetModelToEntityMapper());

  // Data Sources
  sl.registerLazySingleton<IExpenseDataSource>(
    () => ExpenseDataSource(client: sl()),
  );
  sl.registerLazySingleton<IBudgetDataSource>(
    () => BudgetDataSource(client: sl()),
  );

  // Repositories
  sl.registerLazySingleton<IExpenseRepository>(
    () => ExpenseRepository(
      dataSource: sl(),
      expenseToModelMapper: sl(),
      expenseToEntityMapper: sl(),
    ),
  );
  sl.registerLazySingleton<IBudgetRepository>(
    () => BudgetRepository(
      dataSource: sl(),
      entityToModelMapper: sl(),
      modelToEntityMapper: sl(),
    ),
  );

  // Use Cases
  sl.registerFactory(
    () => GetBudgetSummary(expenseRepository: sl()),
  );

  // BLoCs
  sl.registerFactory(
    () => ExpenseFormBloc(
      service: sl(),
      repository: sl(),
      mapper: sl(),
    ),
  );

  sl.registerFactory(
    () => ExpenseListBloc(repository: sl()),
  );

  sl.registerFactory(
    () => BudgetBloc(
      budgetRepository: sl(),
      getBudgetSummary: sl(),
    ),
  );
}
