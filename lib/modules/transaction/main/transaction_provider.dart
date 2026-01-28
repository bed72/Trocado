import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/presentation/cubits/transaction_cubit.dart';

import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';

import 'package:trocado/modules/transaction/data/repositories/transaction_repository.dart';
import 'package:trocado/modules/transaction/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/modules/transaction/infrastructure/datasources/local/transaction_local_datasource.dart';

void transactionProvider() {
  i
    ..registerFactory<TransactionInMapper>(TransactionInMapper.new)
    ..registerFactory<TransactionOutMapper>(TransactionOutMapper.new)
    ..registerFactory<TransactionDtoMapper>(TransactionDtoMapper.new)
    ..registerFactory<ITransactionLocalDatasource>(
      () => TransactionLocalDatasource(client: i.get<IDatabaseClient>()),
    )
    ..registerFactory<ITransactionRepository>(
      () => TransactionRepository(
        inMapper: i.get<TransactionInMapper>(),
        outMapper: i.get<TransactionOutMapper>(),
        datasource: i.get<ITransactionLocalDatasource>(),
      ),
    )
    ..registerLazySingleton<TransactionCubit>(
      () => TransactionCubit(
        formatter: i.get<IMoneyFormatter>(),
        repository: i.get<ITransactionRepository>(),
      ),
      dispose: (cubit) => cubit.close(),
    );
}
