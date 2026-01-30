import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/data/mappers/home_mapper.dart';
import 'package:trocado/modules/home/data/repositories/home_repository.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';
import 'package:trocado/modules/home/infrastructure/datasources/home_local_datasource.dart';

void homeProvider() {
  i
    ..registerFactory<BalanceOutMapper>(BalanceOutMapper.new)
    ..registerFactory<IHomeLocalDatasource>(
      () => HomeLocalDatasource(client: i.get<IDatabaseClient>()),
    )
    ..registerFactory<IHomeRepository>(
      () => HomeRepository(
        datasource: i.get<IHomeLocalDatasource>(),
        balanceOutMapper: i.get<BalanceOutMapper>(),
        transactionDtoMapper: i.get<TransactionDtoMapper>(),
        transactionOutMapper: i.get<TransactionOutMapper>(),
      ),
    )
    ..registerCachedFactory<HomeCubit>(
      () => HomeCubit(
        formatter: i.get<IMoneyFormatter>(),
        repository: i.get<IHomeRepository>(),
      ),
    );
}
