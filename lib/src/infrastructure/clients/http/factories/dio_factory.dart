import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';

import 'package:trocado/src/infrastructure/clients/http/interceptors/authentication_interceptor.dart';

final class DioFactory {
  const DioFactory._();

  static Dio create({
    required String baseUrl,
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
      if (kDebugMode)
        TalkerDioLogger(
          talker: loggerClient,
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: false,
            printResponseMessage: true,
            printResponseHeaders: false,
          ),
        ),
    ]);

    return dio;
  }
}
