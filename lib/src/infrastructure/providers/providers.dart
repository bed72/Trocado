import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';

import 'package:trocado/src/data/repositories/money_repository.dart';
import 'package:trocado/src/data/repositories/logger_repository.dart';
import 'package:trocado/src/data/repositories/transaction_repository.dart';

import 'package:trocado/src/data/datasources/interface_logger_data_source.dart';
import 'package:trocado/src/data/datasources/interface_transaction_data_source.dart';

import 'package:trocado/src/domain/repositories/interface_money_repository.dart';
import 'package:trocado/src/domain/repositories/interface_logger_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/database/database_client.dart';

import 'package:trocado/src/infrastructure/datasources/local/transaction_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/local/logger_local_data_source.dart';

part 'providers.g.dart';

/// CLINETS
@riverpod
ILoggerClient loggerClient(Ref ref) => LoggerClient();

@riverpod
IDatabaseClient databaseClient(Ref ref) =>
    DatabaseClient(client: ref.read(loggerClientProvider));

/// MAPPERS
@riverpod
TransactionToModelMapper transactionToModelMapper(Ref ref) =>
    TransactionToModelMapper();

@riverpod
TransactionToEntityMapper transactionToEntityMapper(Ref ref) =>
    TransactionToEntityMapper();

/// DATASOURCES
@riverpod
ILoggerDataSource loggerDataSource(Ref ref) =>
    LoggerLocalDatasource(client: ref.read(loggerClientProvider));

@riverpod
ITransactionDataSource transactionDataSource(Ref ref) =>
    TransactionDatasource(client: ref.read(databaseClientProvider));

/// REPOSITORIES
@riverpod
IMoneyRepository moneyRepository(Ref ref) => MoneyRepository();

@riverpod
ILoggerRepository loggerRepository(Ref ref) =>
    LoggerRepository(dataSource: ref.read(loggerDataSourceProvider));

@riverpod
ITransactionRepository transactionRepository(Ref ref) => TransactionRepository(
  dataSource: ref.read(transactionDataSourceProvider),
  transactionToModelMapper: ref.read(transactionToModelMapperProvider),
  transactionToEntityMapper: ref.read(transactionToEntityMapperProvider),
);
