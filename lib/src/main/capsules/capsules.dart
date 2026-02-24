import 'package:rearch/rearch.dart';

import 'package:trocado/src/data/services/money_service.dart';

import 'package:trocado/src/data/mapper/expense_mapper.dart';

import 'package:trocado/src/data/repositories/expense_repository.dart';

import 'package:trocado/src/data/datasources/interface_logger_data_source.dart';
import 'package:trocado/src/data/datasources/interface_expense_data_source.dart';

import 'package:trocado/src/domain/services/interface_money_repository.dart';

import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/database/database_client.dart';

import 'package:trocado/src/infrastructure/datasources/local/expense_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/local/logger_local_data_source.dart';

ILoggerClient loggerClientCapsule(CapsuleHandle _) => LoggerClient();
IDatabaseClient databaseClientCapsule(CapsuleHandle use) =>
    DatabaseClient(client: use(loggerClientCapsule));

IMoneyService moneyServiceCapsule(CapsuleHandle _) => MoneyService();

ExpenseEntityToModelMapper expenseEntityToModelMapperCapsule(CapsuleHandle _) =>
    ExpenseEntityToModelMapper();
ExpenseModelToEntityMapper expenseModelToEntityMapperCapsule(CapsuleHandle _) =>
    ExpenseModelToEntityMapper();
ExpensePresentationToModelMapper expensePresentationToModelMapper(
  CapsuleHandle _,
) => ExpensePresentationToModelMapper();

ILoggerDataSource loggerDataSourceCapsule(CapsuleHandle use) =>
    LoggerLocalDatasource(client: use(loggerClientCapsule));
IExpenseDataSource expenseDataSourceCapsule(CapsuleHandle use) =>
    TransactionDataSource(client: use(databaseClientCapsule));

IExpenseRepository expenseRepositoryCapsule(CapsuleHandle use) =>
    ExpenseRepository(
      dataSource: use(expenseDataSourceCapsule),
      transactionToModelMapper: use(expenseEntityToModelMapperCapsule),
      transactionToEntityMapper: use(expenseModelToEntityMapperCapsule),
    );

(AsyncValue<void>, void Function()) ensureInitialized(CapsuleHandle use) {
  final database = use(databaseClientCapsule);

  return use.refreshableFuture(() async => await database.ensureInitialized());
}
