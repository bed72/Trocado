import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/app_check/app_check_client.dart';
import 'package:trocado/src/infrastructure/clients/http/interceptors/app_check_interceptor.dart';

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
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late IAppCheckClient appCheckClient;

  Dio buildDio(_CapturingAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dio.interceptors.add(AppCheckInterceptor(client: appCheckClient));
    dio.httpClientAdapter = adapter;
    return dio;
  }

  setUp(() {
    appCheckClient = MockAppCheckClient();
  });

  group('onRequest', () {
    test('injects X-Firebase-AppCheck header when token is returned', () async {
      when(
        () => appCheckClient.getToken(),
      ).thenAnswer((_) async => 'abc-token');

      final adapter = _CapturingAdapter();
      final dio = buildDio(adapter);

      await dio.get('/api/v1/expenses');

      expect(adapter.lastOptions!.headers['X-Firebase-AppCheck'], 'abc-token');
    });

    test('proceeds without header when token is null', () async {
      when(() => appCheckClient.getToken()).thenAnswer((_) async => null);

      final adapter = _CapturingAdapter();
      final dio = buildDio(adapter);

      await dio.get('/api/v1/expenses');

      expect(
        adapter.lastOptions!.headers.containsKey('X-Firebase-AppCheck'),
        isFalse,
      );
    });

    test('proceeds without header when getToken throws', () async {
      when(() => appCheckClient.getToken()).thenThrow(Exception('boom'));

      final adapter = _CapturingAdapter();
      final dio = buildDio(adapter);

      await dio.get('/api/v1/expenses');

      expect(
        adapter.lastOptions!.headers.containsKey('X-Firebase-AppCheck'),
        isFalse,
      );
    });
  });
}
