import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:trocado/main.dart';

import 'package:trocado/modules/core/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/modules/core/infrastructure/clients/database/database_client.dart';

void provideClients() {
  // client.ensureInitialized();
  provider
    ..registerLazySingleton<IDatabaseClient>(DatabaseClient.new)
    ..registerLazySingleton<IStorageClient>(
      () => StorageClient(storage: provider<FlutterSecureStorage>()),
    );
}
