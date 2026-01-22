import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/presentation/cubits/transaction_cubit.dart';

import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';

import 'package:trocado/modules/transaction/data/repositories/transaction_repository.dart';
import 'package:trocado/modules/transaction/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/modules/transaction/infrastructure/datasources/local/transaction_local_datasource.dart';

void transactionProvider() {
  provider
    ..registerFactory<TransactionInMapper>(TransactionInMapper.new)
    ..registerFactory<TransactionOutMapper>(TransactionOutMapper.new)
    ..registerFactory<TransactionDtoMapper>(TransactionDtoMapper.new)
    ..registerFactory<ITransactionLocalDatasource>(
      () => TransactionLocalDatasource(client: provider.get<IDatabaseClient>()),
    )
    ..registerFactory<ITransactionRepository>(
      () => TransactionRepository(
        inMapper: provider.get<TransactionInMapper>(),
        outMapper: provider.get<TransactionOutMapper>(),
        datasource: provider.get<ITransactionLocalDatasource>(),
      ),
    )
    ..registerLazySingleton<TransactionCubit>(
      () =>
          TransactionCubit(repository: provider.get<ITransactionRepository>()),
      dispose: (cubit) => cubit.close(),
    );
}
