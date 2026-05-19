import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/src/infrastructure/datasources/local/local_theme_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';

part 'storage_provider.g.dart';

@Riverpod(keepAlive: true)
IStorageClient storageClient(Ref ref) =>
    StorageClient(storage: const FlutterSecureStorage());

@Riverpod()
ILocalTokenDataSource localTokenDataSource(Ref ref) =>
    LocalTokenDataSource(client: ref.watch(storageClientProvider));

@Riverpod()
ILocalThemeDataSource localThemeDataSource(Ref ref) =>
    LocalThemeDataSource(client: ref.watch(storageClientProvider));
