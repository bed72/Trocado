import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/data/mappers/home_mapper.dart';
import 'package:trocado/modules/home/data/repositories/home_repository.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';
import 'package:trocado/modules/home/infrastructure/datasources/home_local_datasource.dart';

void homeProvider() {
  provider
    ..registerFactory<BalanceOutMapper>(BalanceOutMapper.new)
    ..registerFactory<IHomeLocalDatasource>(
      () => HomeLocalDatasource(client: provider.get<IDatabaseClient>()),
    )
    ..registerFactory<IHomeRepository>(
      () => HomeRepository(
        datasource: provider.get<IHomeLocalDatasource>(),
        balanceOutMapper: provider.get<BalanceOutMapper>(),
        transactionDtoMapper: provider.get<TransactionDtoMapper>(),
        transactionOutMapper: provider.get<TransactionOutMapper>(),
      ),
    )
    ..registerCachedFactory<HomeCubit>(
      () => HomeCubit(repository: provider.get<IHomeRepository>()),
    );
}
