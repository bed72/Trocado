import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/interceptors/auth_interceptor.dart';

import '../../../../../mocks/mocks.dart';

final class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {'content-type': ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _ServerErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '',
    500,
    headers: {'content-type': ['application/json']},
  );

  @override
  void close({bool force = false}) {}
}

final class _RefreshSuccessAdapter implements HttpClientAdapter {
  bool _firstProtectedCall = true;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('token/refresh')) {
      return ResponseBody.fromString(
        jsonEncode({'access': 'new_access', 'refresh': 'new_refresh'}),
        200,
        headers: {'content-type': ['application/json']},
      );
    }

    if (_firstProtectedCall) {
      _firstProtectedCall = false;
      return ResponseBody.fromString(
        '',
        401,
        headers: {'content-type': ['application/json']},
      );
    }

    return ResponseBody.fromString(
      '{}',
      200,
      headers: {'content-type': ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _RefreshFailureAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'errors': [
        {
          'field': 'non_field_errors',
          'message': 'Token invalid or expired.',
          'code': 'token_not_valid',
        },
      ],
    }),
    401,
    headers: {'content-type': ['application/json']},
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  late MockTokenDataSource tokenDataSource;
  late bool onUnauthenticatedCalled;

  AuthInterceptor buildInterceptor(Dio dio) => AuthInterceptor(
    dio: dio,
    dataSource: tokenDataSource,
    onUnauthenticated: () => onUnauthenticatedCalled = true,
  );

  setUp(() {
    tokenDataSource = MockTokenDataSource();
    onUnauthenticatedCalled = false;
  });

  group('onRequest — public endpoint', () {
    test('does not add Authorization header', () async {
      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      dio.interceptors.add(buildInterceptor(dio));
      dio.httpClientAdapter = adapter;

      await dio.post('/api/v1/token', data: {'email': 'a@b.com'});

      expect(
        adapter.lastOptions!.headers.containsKey(HttpHeaders.authorizationHeader),
        isFalse,
      );
      verifyNever(() => tokenDataSource.get());
    });
  });

  group('onRequest — protected endpoint', () {
    test('adds Authorization header with access token', () async {
      when(() => tokenDataSource.get()).thenAnswer(
        (_) async => (access: 'access_token', refresh: 'refresh_token'),
      );

      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      dio.interceptors.add(buildInterceptor(dio));
      dio.httpClientAdapter = adapter;

      await dio.get('/api/v1/expenses');

      expect(
        adapter.lastOptions!.headers[HttpHeaders.authorizationHeader],
        'Bearer access_token',
      );
    });
  });

  group('onError — non-401', () {
    test('propagates error without attempting refresh', () async {
      when(() => tokenDataSource.get()).thenAnswer(
        (_) async => (access: 'access_token', refresh: 'refresh_token'),
      );

      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      dio.interceptors.add(buildInterceptor(dio));
      dio.httpClientAdapter = _ServerErrorAdapter();

      try {
        await dio.get('/api/v1/expenses');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 500);
      }

      verifyNever(() => tokenDataSource.save(
        access: any(named: 'access'),
        refresh: any(named: 'refresh'),
      ));
    });
  });

  group('onError — 401', () {
    test('refreshes tokens and retries request on success', () async {
      when(() => tokenDataSource.get()).thenAnswer(
        (_) async => (access: 'old_access', refresh: 'old_refresh'),
      );
      when(() => tokenDataSource.save(
        access: any(named: 'access'),
        refresh: any(named: 'refresh'),
      )).thenAnswer((_) async {});

      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      dio.interceptors.add(buildInterceptor(dio));
      dio.httpClientAdapter = _RefreshSuccessAdapter();

      final response = await dio.get('/api/v1/expenses');

      expect(response.statusCode, 200);
      verify(() => tokenDataSource.save(
        access: 'new_access',
        refresh: 'new_refresh',
      )).called(1);
      expect(onUnauthenticatedCalled, isFalse);
    });

    test('clears tokens and calls onUnauthenticated on refresh failure', () async {
      when(() => tokenDataSource.get()).thenAnswer(
        (_) async => (access: 'old_access', refresh: 'expired_refresh'),
      );
      when(() => tokenDataSource.clear()).thenAnswer((_) async {});

      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      dio.interceptors.add(buildInterceptor(dio));
      dio.httpClientAdapter = _RefreshFailureAdapter();

      try {
        await dio.get('/api/v1/expenses');
      } on DioException catch (_) {}

      verify(() => tokenDataSource.clear()).called(1);
      expect(onUnauthenticatedCalled, isTrue);
    });
  });
}
