import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:trocado/src/data/services/money_service.dart';
import 'package:trocado/src/data/mapper/expense_mapper.dart';
import 'package:trocado/src/data/repositories/expense_repository.dart';

import 'package:trocado/src/domain/services/interface_money_repository.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/data/datasources/interface_expense_data_source.dart';
import 'package:trocado/src/infrastructure/clients/database/database_client.dart';
import 'package:trocado/src/infrastructure/datasources/local/expense_data_source.dart';

List<SingleChildWidget> providers() => [
  Provider<ILoggerClient>(create: (_) => LoggerClient()),
  ProxyProvider<ILoggerClient, IDatabaseClient>(
    update: (_, logger, database) => database ?? DatabaseClient(client: logger),
    dispose: (_, database) => database.dispose(),
  ),

  Provider<IMoneyService>(create: (_) => MoneyService()),

  Provider<ExpenseEntityToModelMapper>(
    create: (_) => ExpenseEntityToModelMapper(),
  ),
  Provider<ExpenseModelToEntityMapper>(
    create: (_) => ExpenseModelToEntityMapper(),
  ),
  Provider<ExpensePresentationToModelMapper>(
    create: (_) => ExpensePresentationToModelMapper(),
  ),

  ProxyProvider<IDatabaseClient, IExpenseDataSource>(
    update: (_, database, dataSource) =>
        dataSource ?? TransactionDataSource(client: database),
  ),

  ProxyProvider3<
    IExpenseDataSource,
    ExpenseEntityToModelMapper,
    ExpenseModelToEntityMapper,
    IExpenseRepository
  >(
    update: (_, dataSource, entityToModel, modelToEntity, repository) =>
        repository ??
        ExpenseRepository(
          dataSource: dataSource,
          transactionToModelMapper: entityToModel,
          transactionToEntityMapper: modelToEntity,
        ),
  ),
];
