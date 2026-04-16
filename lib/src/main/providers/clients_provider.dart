import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/main/config/app_config.dart';
import 'package:trocado/src/main/providers/storage_provider.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/http/factories/dio_factory.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/sign_in_location.dart';

part 'clients_provider.g.dart';

@Riverpod(keepAlive: true)
ILoggerClient loggerClient(Ref _) => LoggerClient();

@Riverpod(keepAlive: true)
IHttpClient httpClient(Ref ref) => HttpClient(dio: ref.watch(dioProvider));

@Riverpod(keepAlive: true)
Dio dio(Ref ref) => DioFactory.create(
  baseUrl: AppConfig.url,
  dataSource: ref.watch(localTokenDataSourceProvider),
  onUnauthenticated: () =>
      routerConfig.navigate(root: true, replace: true, to: SignInLocation()),
);
