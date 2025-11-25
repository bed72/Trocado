import 'package:provider/provider.dart';

import 'package:trocado/modules/core/data/repositories/storage_repositor.dart';
import 'package:trocado/modules/core/data/datasources/interface_storage_datasource.dart';

import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final repositoryProvider = [
  Provider<IStorageRepository>(
    create: (context) =>
        StorageRepository(datasource: context.read<IStorageDatasource>()),
  ),
];
