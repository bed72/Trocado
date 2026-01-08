import 'package:image_picker/image_picker.dart';

import 'package:trocado/main.dart';

import 'package:trocado/modules/core/data/datasources/interface_image_datasource.dart';
import 'package:trocado/modules/core/data/datasources/interface_storage_datasource.dart';
import 'package:trocado/modules/core/data/datasources/interface_database_datasource.dart';

import 'package:trocado/modules/core/infrastructure/resources/loggers/logger.dart';

import 'package:trocado/modules/core/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/modules/core/infrastructure/clients/database/database_client.dart';

import 'package:trocado/modules/core/infrastructure/datasources/local/image_datasource.dart';
import 'package:trocado/modules/core/infrastructure/datasources/local/storage_datasource.dart';
import 'package:trocado/modules/core/infrastructure/datasources/local/database_datasource.dart';

void datasourceProvider() {
  provider
    ..registerLazySingleton<IImageDatasource>(
      () => ImageDatasource(client: ImagePicker()),
    )
    ..registerLazySingleton<IStorageDatasource>(
      () => StorageDatasource(client: provider<IStorageClient>()),
    )
    ..registerLazySingleton<IDatabaseDatasource>(
      () => DatabaseDatasource(
        logger: provider.get<ILogger>(),
        client: provider<IDatabaseClient>(),
      ),
    );
}
