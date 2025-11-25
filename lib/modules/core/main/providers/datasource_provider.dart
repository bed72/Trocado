import 'package:provider/provider.dart';

import 'package:trocado/modules/core/data/datasources/interface_storage_datasource.dart';
import 'package:trocado/modules/core/data/datasources/interface_database_datasource.dart';

import 'package:trocado/modules/core/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/modules/core/infrastructure/clients/database/database_client.dart';

import 'package:trocado/modules/core/infrastructure/datasources/local/storage_datasource.dart';
import 'package:trocado/modules/core/infrastructure/datasources/local/database_datasource.dart';

final datasourceProvider = [
  Provider<IStorageDatasource>(
    create: (context) =>
        StorageDatasource(client: context.read<IStorageClient>()),
  ),

  Provider<IDatabaseDatasource>(
    create: (context) =>
        DatabaseDatasource(client: context.read<IDatabaseClient>()),
  ),
];
