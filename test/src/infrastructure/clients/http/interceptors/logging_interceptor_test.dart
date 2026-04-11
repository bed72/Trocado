import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/interceptors/logging_interceptor.dart';

import '../../../../../mocks/mocks.dart';

final class _FakeResponseAdapter implements HttpClientAdapter {
  final int statusCode;
  final Map<String, dynamic> data;

  const _FakeResponseAdapter({required this.statusCode, required this.data});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      'content-type': ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

final class _FakeNetworkFailureAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw Exception('Connection refused');

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(LoggingInterceptor interceptor, HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
  dio.interceptors.add(interceptor);
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  late LoggingInterceptor sut;
  late MockLoggerClient logger;

  setUp(() {
    logger = MockLoggerClient();
    sut = LoggingInterceptor(logger: logger);
  });

  group('onRequest', () {
    test('logs method, path, query, headers and body', () async {
      final Dio dio = _dioWith(
        sut,
        _FakeResponseAdapter(statusCode: 200, data: {'ok': true}),
      );

      await dio.post(
        '/auth/sign-in',
        data: {'email': 'a@b.com'},
        queryParameters: {'page': '1'},
        options: Options(headers: {'X-Custom': 'value'}),
      );

      verify(
        () => logger.debug('[POST] /auth/sign-in', error: any(named: 'error')),
      ).called(1);
    });
  });

  group('onResponse', () {
    test('logs status code, path and response body', () async {
      final Dio dio = _dioWith(
        sut,
        _FakeResponseAdapter(statusCode: 200, data: {'token': 'abc'}),
      );

      await dio.get('/auth/sign-in');

      verify(
        () => logger.debug('[200] /auth/sign-in', error: any(named: 'error')),
      ).called(1);
    });
  });

  group('onError', () {
    test(
      'logs status code, path and error body when response is available',
      () async {
        final Map<String, dynamic> errorBody = {
          'errors': [
            {
              'field': 'non_field_errors',
              'message': 'Invalid credentials.',
              'code': 'invalid',
            },
          ],
        };
        final Dio dio = _dioWith(
          sut,
          _FakeResponseAdapter(statusCode: 401, data: errorBody),
        );

        try {
          await dio.get('/auth/sign-in');
        } on DioException catch (_) {}

        verify(
          () => logger.error('[401] /auth/sign-in', error: any(named: 'error')),
        ).called(1);
      },
    );

    test(
      'logs null status and error message when response is unavailable',
      () async {
        final Dio dio = _dioWith(sut, _FakeNetworkFailureAdapter());

        try {
          await dio.get('/auth/sign-in');
        } on DioException catch (_) {}

        verify(
          () =>
              logger.error('[null] /auth/sign-in', error: any(named: 'error')),
        ).called(1);
      },
    );
  });
}
