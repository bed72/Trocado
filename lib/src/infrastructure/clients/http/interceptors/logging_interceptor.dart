import 'package:dio/dio.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';

final class LoggingInterceptor extends Interceptor {
  final ILoggerClient _logger;

  LoggingInterceptor({required ILoggerClient logger}) : _logger = logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug(
      '[${options.method}] ${options.path}',
      error: {
        'body': options.data,
        'headers': options.headers,
        'query': options.queryParameters,
      },
    );

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.debug(
      '[${response.statusCode}] ${response.requestOptions.path}',
      error: response.data,
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.error(
      '[${err.response?.statusCode}] ${err.requestOptions.path}',
      error: err.response?.data ?? err.message,
    );

    handler.next(err);
  }
}
