import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

import 'package:trocado/modules/core/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/modules/core/infrastructure/clients/database/database_client.dart';

final clientProvider = [
  Provider<IStorageClient>(
    create: (context) =>
        StorageClient(storage: context.get<FlutterSecureStorage>()),
  ),
  Provider<IDatabaseClient>(
    create: (_) {
      final client = DatabaseClient();

      client.ensureInitialized();

      return client;
    },
  ),
];
