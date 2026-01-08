import 'package:trocado/main.dart';

import 'package:trocado/modules/core/data/repositories/storage_repository.dart';
import 'package:trocado/modules/core/data/datasources/interface_storage_datasource.dart';

import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

void repositoryProvider() {
  provider.registerLazySingleton<IStorageRepository>(
    () => StorageRepository(datasource: provider<IStorageDatasource>()),
  );
}
