import 'package:dio/dio.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/reponses.dart';

abstract interface class IHttpClient {
  Future<Responses> get({required Requests parameter});
  Future<Responses> put({required Requests parameter});
  Future<Responses> post({required Requests parameter});
  Future<Responses> patch({required Requests parameter});
  Future<Responses> delete({required Requests parameter});
}

final class HttpClient implements IHttpClient {
  final Dio _dio;

  HttpClient({required this._dio});

  @override
  Future<Responses> get({required Requests parameter}) => _execute(
    () => _dio.get<Map<String, dynamic>>(
      parameter.path,
      queryParameters: parameter.query,
      options: Options(headers: parameter.headers),
    ),
  );

  @override
  Future<Responses> post({required Requests parameter}) => _execute(
    () => _dio.post<Map<String, dynamic>>(
      parameter.path,
      data: parameter.body,
      queryParameters: parameter.query,
      options: Options(headers: parameter.headers),
    ),
  );

  @override
  Future<Responses> put({required Requests parameter}) => _execute(
    () => _dio.put<Map<String, dynamic>>(
      parameter.path,
      data: parameter.body,
      queryParameters: parameter.query,
      options: Options(headers: parameter.headers),
    ),
  );

  @override
  Future<Responses> patch({required Requests parameter}) => _execute(
    () => _dio.patch<Map<String, dynamic>>(
      parameter.path,
      data: parameter.body,
      queryParameters: parameter.query,
      options: Options(headers: parameter.headers),
    ),
  );

  @override
  Future<Responses> delete({required Requests parameter}) => _execute(
    () => _dio.delete<Map<String, dynamic>>(
      parameter.path,
      data: parameter.body,
      queryParameters: parameter.query,
      options: Options(headers: parameter.headers),
    ),
  );

  Future<Responses> _execute(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    try {
      final Response(data: data) = await call();

      return Right(data ?? {});
    } on DioException catch (exception) {
      return Left(_mapFailure(exception));
    } catch (_) {
      return Left(_unknownFailure());
    }
  }

  Map<String, dynamic> _unknownFailure() => {
    'errors': [
      {
        'code': 'unknown',
        'message': 'Unknown error',
        'source': {'field': 'non_field_errors'},
      },
    ],
  };

  Map<String, dynamic> _mapFailure(DioException exception) {
    final response = exception.response?.data;

    return response is Map<String, dynamic>
        ? response
        : {
            'errors': [
              {
                'code': 'network_error',
                'source': {'field': 'non_field_errors'},
                'message': exception.message ?? 'Network error',
              },
            ],
          };
  }
}
