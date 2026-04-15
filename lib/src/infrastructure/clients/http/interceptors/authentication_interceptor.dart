import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';

final class AuthenticationInterceptor extends Interceptor {
  final Dio _dio;
  final VoidCallback _onUnauthenticated;
  final ILocalTokenDataSource _dataSource;

  AuthenticationInterceptor({
    required Dio dio,
    required VoidCallback onUnauthenticated,
    required ILocalTokenDataSource dataSource,
  }) : _dio = dio,
       _dataSource = dataSource,
       _onUnauthenticated = onUnauthenticated;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (EndpointKey.isPublicPath(options.path)) return handler.next(options);

    final tokens = await _dataSource.get();
    if (tokens.access != null) {
      options.headers[HttpHeaders.authorizationHeader] =
          'Bearer ${tokens.access}';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != HttpStatus.unauthorized) {
      return handler.next(err);
    }

    if (EndpointKey.isPublicPath(err.requestOptions.path)) {
      return handler.next(err);
    }

    try {
      final tokens = await _dataSource.get();
      final Response(data: data) = await _dio.post<Map<String, dynamic>>(
        EndpointKey.refreshToken.path,
        data: {'refresh': tokens.refresh},
      );

      final access = data!['access'] as String;
      final refresh = data['refresh'] as String;
      await _dataSource.save(access: access, refresh: refresh);

      err.requestOptions.headers[HttpHeaders.authorizationHeader] =
          'Bearer $access';

      handler.resolve(await _dio.fetch(err.requestOptions));
    } catch (_) {
      await _dataSource.clear();
      _onUnauthenticated();
      handler.next(err);
    }
  }
}
