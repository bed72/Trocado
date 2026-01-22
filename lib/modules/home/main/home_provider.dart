import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/data/repositories/home_repository.dart';
import 'package:trocado/modules/home/domain/repositories/interface_home_repository.dart';
import 'package:trocado/modules/home/infrastructure/datasources/home_local_datasource.dart';

void homeProvider() {
  provider
    ..registerFactory<IHomeLocalDatasource>(
      () => HomeLocalDatasource(client: provider.get<IDatabaseClient>()),
    )
    ..registerFactory<IHomeRepository>(
      () => HomeRepository(
        dtoMapper: provider.get<TransactionDtoMapper>(),
        outMapper: provider.get<TransactionOutMapper>(),
        datasource: provider.get<IHomeLocalDatasource>(),
      ),
    )
    ..registerCachedFactory<HomeCubit>(
      () => HomeCubit(repository: provider.get<IHomeRepository>()),
    );
}
