import 'package:provider/provider.dart';
import 'package:trocado/modules/core/data/datasources/interface_image_datasource.dart';
import 'package:trocado/modules/core/data/repositories/image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

import 'package:trocado/modules/core/data/repositories/storage_repository.dart';
import 'package:trocado/modules/core/data/datasources/interface_storage_datasource.dart';

import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final repositoryProvider = [
  Provider<IImageRepository>(
    create: (context) =>
        ImageRepository(datasource: context.get<IImageDatasource>()),
  ),

  Provider<IStorageRepository>(
    create: (context) =>
        StorageRepository(datasource: context.get<IStorageDatasource>()),
  ),
];
