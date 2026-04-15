import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/main/config/app_config.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/sign_in_location.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';
import 'package:trocado/src/infrastructure/clients/http/interceptors/auth_interceptor.dart';
import 'package:trocado/src/infrastructure/clients/http/interceptors/logging_interceptor.dart';

part 'clients_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.url));
  final tokenDataSource = LocalTokenDataSource(
    client: ref.watch(storageClientProvider),
  );
  dio.interceptors.addAll([
    AuthInterceptor(
      dio: dio,
      dataSource: tokenDataSource,
      onUnauthenticated: () => routerConfig.navigate(
        root: true,
        replace: true,
        to: SignInLocation(),
      ),
    ),
    LoggingInterceptor(logger: LoggerClient()),
  ]);
  return dio;
}

@Riverpod(keepAlive: true)
IStorageClient storageClient(Ref ref) =>
    StorageClient(storage: const FlutterSecureStorage());

@Riverpod(keepAlive: true)
IHttpClient httpClient(Ref ref) => HttpClient(dio: ref.watch(dioProvider));
