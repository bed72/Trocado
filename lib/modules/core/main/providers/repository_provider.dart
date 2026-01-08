import 'package:trocado/main.dart';

import 'package:trocado/modules/core/data/mapper/user_mapper.dart';

import 'package:trocado/modules/core/data/repositories/user_repository.dart';
import 'package:trocado/modules/core/data/repositories/image_repository.dart';
import 'package:trocado/modules/core/data/repositories/storage_repository.dart';

import 'package:trocado/modules/core/data/datasources/interface_image_datasource.dart';
import 'package:trocado/modules/core/data/datasources/interface_storage_datasource.dart';
import 'package:trocado/modules/core/data/datasources/interface_database_datasource.dart';

import 'package:trocado/modules/core/domain/repositories/interface_user_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

void repositoryProvider() {
  provider
    ..registerLazySingleton<IUserRepository>(
      () => UserRepository(
        mapper: UserMapper(),
        datasource: provider<IDatabaseDatasource>(),
      ),
    )
    ..registerLazySingleton<IImageRepository>(
      () => ImageRepository(datasource: provider<IImageDatasource>()),
    )
    ..registerLazySingleton<IStorageRepository>(
      () => StorageRepository(datasource: provider<IStorageDatasource>()),
    );
}
