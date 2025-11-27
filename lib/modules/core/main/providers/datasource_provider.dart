import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

import 'package:trocado/modules/core/data/datasources/interface_image_datasource.dart';
import 'package:trocado/modules/core/data/datasources/interface_storage_datasource.dart';
import 'package:trocado/modules/core/data/datasources/interface_database_datasource.dart';

import 'package:trocado/modules/core/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/modules/core/infrastructure/clients/database/database_client.dart';

import 'package:trocado/modules/core/infrastructure/datasources/local/image_datasource.dart';
import 'package:trocado/modules/core/infrastructure/datasources/local/storage_datasource.dart';
import 'package:trocado/modules/core/infrastructure/datasources/local/database_datasource.dart';

final datasourceProvider = [
  Provider<IImageDatasource>(
    create: (_) => ImageDatasource(client: ImagePicker()),
  ),

  Provider<IStorageDatasource>(
    create: (context) =>
        StorageDatasource(client: context.get<IStorageClient>()),
  ),

  Provider<IDatabaseDatasource>(
    create: (context) =>
        DatabaseDatasource(client: context.get<IDatabaseClient>()),
  ),
];
