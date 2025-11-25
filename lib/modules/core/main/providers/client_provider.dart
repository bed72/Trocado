import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:trocado/modules/core/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/modules/core/infrastructure/clients/database/database_client.dart';
import 'package:trocado/modules/core/infrastructure/clients/external/external_client.dart';

final clientProvider = [
  Provider<IExternalClient>(create: (_) => ExternalClient()),
  Provider<IStorageClient>(
    create: (context) =>
        StorageClient(storage: context.read<FlutterSecureStorage>()),
  ),
  Provider<IDatabaseClient>(
    create: (_) {
      final client = DatabaseClient();

      client.ensureInitialized();

      return client;
    },
  ),
];
