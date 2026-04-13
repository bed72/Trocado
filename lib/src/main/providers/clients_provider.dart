import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:trocado/src/main/config/app_config.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';

part 'clients_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref _) => Dio(BaseOptions(baseUrl: AppConfig.url));

@Riverpod(keepAlive: true)
IStorageClient storageClient(Ref ref) =>
    StorageClient(storage: const FlutterSecureStorage());

@Riverpod(keepAlive: true)
IHttpClient httpClient(Ref ref) => HttpClient(dio: ref.watch(dioProvider));
