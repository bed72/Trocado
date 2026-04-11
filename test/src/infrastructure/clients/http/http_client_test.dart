import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/request.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late MockDio dio;
  late DioHttpClient sut;

  setUp(() {
    dio = MockDio();
    sut = DioHttpClient(dio: dio);
  });

  DioException networkError() => DioException(
    type: .connectionError,
    message: 'Connection refused',
    requestOptions: RequestOptions(),
  );

  Response<Map<String, dynamic>> successResponse(Map<String, dynamic> data) =>
      Response(data: data, statusCode: 200, requestOptions: RequestOptions());

  DioException dioErrorWithResponse(Map<String, dynamic> body, int status) =>
      DioException(
        type: .badResponse,
        requestOptions: RequestOptions(),
        response: Response(
          data: body,
          statusCode: status,
          requestOptions: RequestOptions(),
        ),
      );

  group('GET', () {
    test('returns Right with body on success', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => successResponse({'id': 1}));

      final data = await sut.get(parameter: const Request('/endpoint'));

      expect(data.isRight, isTrue);
      expect(data.right, {'id': 1});
    });

    test('returns Left with HTTP error body', () async {
      final body = {
        'errors': [
          {
            'code': 'not_found',
            'message': 'Not found.',
            'field': 'non_field_errors',
          },
        ],
      };

      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioErrorWithResponse(body, 404));

      final data = await sut.get(parameter: const Request('/endpoint'));

      expect(data.left, body);
      expect(data.isLeft, isTrue);
    });

    test('returns normalized Left on network error', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(networkError());

      final data = await sut.get(parameter: const Request('/endpoint'));

      expect(data.isLeft, isTrue);
      final errors = data.left['errors'] as List;
      expect(errors.first['code'], 'network_error');
    });

    test('returns normalized Left on unexpected error', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(Exception('unexpected'));

      final data = await sut.get(parameter: const Request('/endpoint'));

      expect(data.isLeft, isTrue);
      final errors = data.left['errors'] as List;
      expect(errors.first['code'], 'unknown');
    });
  });

  group('POST', () {
    test('returns Right with body on success', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => successResponse({'token': 'abc'}));

      final data = await sut.post(
        parameter: const Request('/auth', body: {'email': 'a@b.com'}),
      );

      expect(data.isRight, isTrue);
      expect(data.right, {'token': 'abc'});
    });

    test('returns Left with body on 400 error', () async {
      final body = {
        'errors': [
          {
            'field': 'email',
            'code': 'required',
            'message': 'This field is required.',
          },
        ],
      };

      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(dioErrorWithResponse(body, 400));

      final data = await sut.post(parameter: const Request('/auth'));

      expect(data.left, body);
      expect(data.isLeft, isTrue);
    });
  });

  group('PUT', () {
    test('returns Right with body on success', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => successResponse({'updated': true}));

      final data = await sut.put(
        parameter: const Request('/resource/1', body: {'name': 'test'}),
      );

      expect(data.isRight, isTrue);
    });
  });

  group('PATCH', () {
    test('returns Right with body on success', () async {
      when(
        () => dio.patch<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => successResponse({'patched': true}));

      final data = await sut.patch(
        parameter: const Request('/resource/1', body: {'name': 'test'}),
      );

      expect(data.isRight, isTrue);
    });
  });

  group('DELETE', () {
    test('returns Right with body on success', () async {
      when(
        () => dio.delete<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => successResponse({}));

      final data = await sut.delete(parameter: const Request('/resource/1'));

      expect(data.isRight, isTrue);
    });
  });
}
