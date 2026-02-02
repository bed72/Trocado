import 'package:trocado/main.dart';

import 'package:trocado/src/data/mapper/balance_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';

import 'package:trocado/src/presentation/cubits/home/home_cubit.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

import 'package:trocado/src/data/repositories/money_repository.dart';
import 'package:trocado/src/data/repositories/logger_repository.dart';
import 'package:trocado/src/data/repositories/transaction_repository.dart';

import 'package:trocado/src/domain/repositories/interface_money_repository.dart';
import 'package:trocado/src/domain/repositories/interface_logger_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/database/database_client.dart';

import 'package:trocado/src/infrastructure/datasources/local/logger_local_datasource.dart';
import 'package:trocado/src/infrastructure/datasources/local/transaction_local_datasource.dart';

void providers() {
  // Clients
  i
    ..registerLazySingleton<ILoggerClient>(LoggerClient.new)
    ..registerLazySingleton<IDatabaseClient>(
      () => DatabaseClient(client: i.get<ILoggerClient>()),
    );

  // Mappers
  i
    ..registerFactory<BalanceToModelMapper>(BalanceToModelMapper.new)
    ..registerFactory<TransactionToModelMapper>(TransactionToModelMapper.new)
    ..registerFactory<TransactionToEntityMapper>(TransactionToEntityMapper.new);

  // Datasources
  i
    ..registerFactory<ILoggerLocalDatasource>(
      () => LoggerLocalDatasource(client: i.get<ILoggerClient>()),
    )
    ..registerFactory<ITransactionLocalDatasource>(
      () => TransactionLocalDatasource(client: i.get<IDatabaseClient>()),
    );

  // Repositories
  i
    ..registerFactory<IMoneyRepository>(MoneyRepository.new)
    ..registerFactory<ILoggerRepository>(
      () => LoggerRepository(datasource: i.get<ILoggerLocalDatasource>()),
    )
    ..registerFactory<ITransactionRepository>(
      () => TransactionRepository(
        datasource: i.get<ITransactionLocalDatasource>(),
        balanceToModelMapper: i.get<BalanceToModelMapper>(),
        transactionToModelMapper: i.get<TransactionToModelMapper>(),
        transactionToEntityMapper: i.get<TransactionToEntityMapper>(),
      ),
    );

  // Cubits
  i
    ..registerLazySingleton<TransactionCubit>(
      () => TransactionCubit(
        formatter: i.get<IMoneyRepository>(),
        repository: i.get<ITransactionRepository>(),
      ),
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<HomeCubit>(
      () => HomeCubit(
        moneyRepository: i.get<IMoneyRepository>(),
        transactionCubit: i.get<TransactionCubit>(),
        transactionRepository: i.get<ITransactionRepository>(),
      ),
      dispose: (cubit) => cubit.close(),
    );
}
