import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/http/interceptors/logging_interceptor.dart';
import 'package:trocado/src/infrastructure/clients/http/interceptors/authentication_interceptor.dart';

final class DioFactory {
  const DioFactory._();

  static Dio create({
    required String baseUrl,
    required ILoggerClient logger,
    required VoidCallback onUnauthenticated,
    required ILocalTokenDataSource dataSource,
  }) {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));

    dio.interceptors.addAll([
      AuthenticationInterceptor(
        dio: dio,
        dataSource: dataSource,
        onUnauthenticated: onUnauthenticated,
      ),
      LoggingInterceptor(logger: logger),
    ]);

    return dio;
  }
}
