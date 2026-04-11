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

  HttpClient({required Dio dio}) : _dio = dio;

  @override
  Future<Responses> get({required Requests parameter}) async {
    try {
      final Response(data: data) = await _dio.get<Map<String, dynamic>>(
        parameter.path,
        queryParameters: parameter.query,
        options: Options(headers: parameter.headers),
      );

      return Right(data ?? {});
    } on DioException catch (exception) {
      return Left(_mapFailure(exception));
    } catch (_) {
      return Left(_unknownFailure());
    }
  }

  @override
  Future<Responses> post({required Requests parameter}) async {
    try {
      final Response(data: data) = await _dio.post<Map<String, dynamic>>(
        parameter.path,
        data: parameter.body,
        queryParameters: parameter.query,
        options: Options(headers: parameter.headers),
      );

      return Right(data ?? {});
    } on DioException catch (exception) {
      return Left(_mapFailure(exception));
    } catch (_) {
      return Left(_unknownFailure());
    }
  }

  @override
  Future<Responses> put({required Requests parameter}) async {
    try {
      final Response(data: data) = await _dio.put<Map<String, dynamic>>(
        parameter.path,
        data: parameter.body,
        queryParameters: parameter.query,
        options: Options(headers: parameter.headers),
      );

      return Right(data ?? {});
    } on DioException catch (exception) {
      return Left(_mapFailure(exception));
    } catch (_) {
      return Left(_unknownFailure());
    }
  }

  @override
  Future<Responses> patch({required Requests parameter}) async {
    try {
      final Response(data: data) = await _dio.patch<Map<String, dynamic>>(
        parameter.path,
        data: parameter.body,
        queryParameters: parameter.query,
        options: Options(headers: parameter.headers),
      );

      return Right(data ?? {});
    } on DioException catch (exception) {
      return Left(_mapFailure(exception));
    } catch (_) {
      return Left(_unknownFailure());
    }
  }

  @override
  Future<Responses> delete({required Requests parameter}) async {
    try {
      final Response(data: data) = await _dio.delete<Map<String, dynamic>>(
        parameter.path,
        data: parameter.body,
        queryParameters: parameter.query,
        options: Options(headers: parameter.headers),
      );

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
        'field': 'non_field_errors',
      },
    ],
  };

  Map<String, dynamic> _mapFailure(DioException exception) =>
      exception.response != null
      ? exception.response!.data as Map<String, dynamic>
      : {
          'errors': [
            {
              'code': 'network_error',
              'field': 'non_field_errors',
              'message': exception.message ?? 'Network error',
            },
          ],
        };
}
