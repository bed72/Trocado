import 'package:trocado/main.dart';

import 'package:trocado/src/data/mapper/balance_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';

import 'package:trocado/src/data/repositories/home_repository.dart';
import 'package:trocado/src/data/repositories/transaction_repository.dart';

import 'package:trocado/src/domain/repositories/interface_home_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/presentation/cubits/date/date_cubit.dart';
import 'package:trocado/src/presentation/cubits/home/home_cubit.dart';
import 'package:trocado/src/presentation/cubits/category/category_cubit.dart';
import 'package:trocado/src/presentation/cubits/calculator/calculator_cubit.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

import 'package:trocado/src/infrastructure/clients/database/database_client.dart';

import 'package:trocado/src/infrastructure/resources/loggers/logger.dart';
import 'package:trocado/src/infrastructure/resources/formatters/money_formatter.dart';
import 'package:trocado/src/infrastructure/datasources/local/home_local_datasource.dart';
import 'package:trocado/src/infrastructure/datasources/local/transaction_local_datasource.dart';

void providers() {
  // Others
  i
    ..registerFactory<ILogger>(Logger.new)
    ..registerFactory<IMoneyFormatter>(MoneyFormatter.new);

  // Clients
  i.registerLazySingleton<IDatabaseClient>(
    () => DatabaseClient(logger: i.get<ILogger>()),
  );

  // Mappers
  i
    ..registerFactory<BalanceToModelMapper>(BalanceToModelMapper.new)
    ..registerFactory<TransactionToModelMapper>(TransactionToModelMapper.new)
    ..registerFactory<TransactionToEntityMapper>(TransactionToEntityMapper.new);

  // Datasources
  i
    ..registerFactory<IHomeLocalDatasource>(
      () => HomeLocalDatasource(client: i.get<IDatabaseClient>()),
    )
    ..registerFactory<ITransactionLocalDatasource>(
      () => TransactionLocalDatasource(client: i.get<IDatabaseClient>()),
    );

  // Repositories
  i
    ..registerFactory<IHomeRepository>(
      () => HomeRepository(
        datasource: i.get<IHomeLocalDatasource>(),
        balanceToModelMapper: i.get<BalanceToModelMapper>(),
        transactionToModelMapper: i.get<TransactionToModelMapper>(),
      ),
    )
    ..registerFactory<ITransactionRepository>(
      () => TransactionRepository(
        datasource: i.get<ITransactionLocalDatasource>(),
        toModelMapper: i.get<TransactionToModelMapper>(),
        toEntityMapper: i.get<TransactionToEntityMapper>(),
      ),
    );

  // Cubits
  i
    ..registerLazySingleton<DateCubit>(
      DateCubit.new,
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<CategoryCubit>(
      CategoryCubit.new,
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<CalculatorCubit>(
      () => CalculatorCubit(formatter: i.get<IMoneyFormatter>()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<HomeCubit>(
      () => HomeCubit(
        formatter: i.get<IMoneyFormatter>(),
        repository: i.get<IHomeRepository>(),
      ),
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<TransactionCubit>(
      () => TransactionCubit(
        formatter: i.get<IMoneyFormatter>(),
        repository: i.get<ITransactionRepository>(),
      ),
      dispose: (cubit) => cubit.close(),
    );
}
