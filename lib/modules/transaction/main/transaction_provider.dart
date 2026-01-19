import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/data/mappers/transaction_mapper.dart';
import 'package:trocado/modules/transaction/data/datasources/interface_transaction_datasource.dart';

import 'package:trocado/modules/transaction/infrastructure/datasources/local/transaction_local_datasource.dart';

void transactionProvider() {
  provider
    ..registerFactory<TransactionInMapper>(TransactionInMapper.new)
    ..registerFactory<TransactionOutMapper>(TransactionOutMapper.new)
    ..registerFactory<ITransactionLocalDatasource>(
      () => TransactionLocalDatasource(client: provider.get<IDatabaseClient>()),
    );
}
