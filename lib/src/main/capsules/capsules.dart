import 'package:rearch/rearch.dart';

import 'package:trocado/src/data/services/money_service.dart';

import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';

import 'package:trocado/src/data/repositories/transaction_repository.dart';

import 'package:trocado/src/data/datasources/interface_logger_data_source.dart';
import 'package:trocado/src/data/datasources/interface_transaction_data_source.dart';

import 'package:trocado/src/domain/services/interface_money_repository.dart';

import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/database/database_client.dart';

import 'package:trocado/src/infrastructure/datasources/local/transaction_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/local/logger_local_data_source.dart';

ILoggerClient loggerClientCapsule(CapsuleHandle _) => LoggerClient();
IDatabaseClient databaseClientCapsule(CapsuleHandle use) =>
    DatabaseClient(client: use(loggerClientCapsule));

IMoneyService moneyServiceCapsule(CapsuleHandle _) => MoneyService();

TransactionToModelMapper transactionToModelMapperCapsule(CapsuleHandle _) =>
    TransactionToModelMapper();
TransactionToEntityMapper transactionToEntityMapperCapsule(CapsuleHandle _) =>
    TransactionToEntityMapper();

ILoggerDataSource loggerDataSourceCapsule(CapsuleHandle use) =>
    LoggerLocalDatasource(client: use(loggerClientCapsule));
ITransactionDataSource transactionDataSourceCapsule(CapsuleHandle use) =>
    TransactionDataSource(client: use(databaseClientCapsule));

ITransactionRepository transactionRepositoryCapsule(CapsuleHandle use) =>
    TransactionRepository(
      dataSource: use(transactionDataSourceCapsule),
      transactionToModelMapper: use(transactionToModelMapperCapsule),
      transactionToEntityMapper: use(transactionToEntityMapperCapsule),
    );

//   i
//     ..registerLazySingleton<DateStore>(DateStore.new)
//     ..registerLazySingleton<CategoryStore>(CategoryStore.new)
//     ..registerLazySingleton<TransactionStore>(TransactionStore.new);
// }
