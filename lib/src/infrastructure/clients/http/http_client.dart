import 'package:dio/dio.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/requests/request.dart';

typedef Result = Either<Map<String, dynamic>, Map<String, dynamic>>;

abstract interface class IHttpClient {
  Future<Result> get({required Request parameter});
  Future<Result> put({required Request parameter});
  Future<Result> post({required Request parameter});
  Future<Result> patch({required Request parameter});
  Future<Result> delete({required Request parameter});
}

final class DioHttpClient implements IHttpClient {
  final Dio _dio;

  DioHttpClient({required Dio dio}) : _dio = dio;

  @override
  Future<Result> get({required Request parameter}) async {
    try {
      final Response(data: data) = await _dio.get<Map<String, dynamic>>(
        parameter.path,
        queryParameters: parameter.query,
        options: Options(headers: parameter.headers),
      );

      return Right(data ?? {});
    } on DioException catch (exception) {
      return Left(_mapDioError(exception));
    } catch (_) {
      return Left(_unknownError());
    }
  }

  @override
  Future<Result> post({required Request parameter}) async {
    try {
      final Response(data: data) = await _dio.post<Map<String, dynamic>>(
        parameter.path,
        data: parameter.body,
        queryParameters: parameter.query,
        options: Options(headers: parameter.headers),
      );

      return Right(data ?? {});
    } on DioException catch (exception) {
      return Left(_mapDioError(exception));
    } catch (_) {
      return Left(_unknownError());
    }
  }

  @override
  Future<Result> put({required Request parameter}) async {
    try {
      final Response(data: data) = await _dio.put<Map<String, dynamic>>(
        parameter.path,
        data: parameter.body,
        queryParameters: parameter.query,
        options: Options(headers: parameter.headers),
      );

      return Right(data ?? {});
    } on DioException catch (exception) {
      return Left(_mapDioError(exception));
    } catch (_) {
      return Left(_unknownError());
    }
  }

  @override
  Future<Result> patch({required Request parameter}) async {
    try {
      final Response(data: data) = await _dio.patch<Map<String, dynamic>>(
        parameter.path,
        data: parameter.body,
        queryParameters: parameter.query,
        options: Options(headers: parameter.headers),
      );

      return Right(data ?? {});
    } on DioException catch (exception) {
      return Left(_mapDioError(exception));
    } catch (_) {
      return Left(_unknownError());
    }
  }

  @override
  Future<Result> delete({required Request parameter}) async {
    try {
      final Response(data: data) = await _dio.delete<Map<String, dynamic>>(
        parameter.path,
        data: parameter.body,
        queryParameters: parameter.query,
        options: Options(headers: parameter.headers),
      );

      return Right(data ?? {});
    } on DioException catch (exception) {
      return Left(_mapDioError(exception));
    } catch (_) {
      return Left(_unknownError());
    }
  }

  Map<String, dynamic> _unknownError() => {
    'errors': [
      {
        'code': 'unknown',
        'message': 'Unknown error',
        'field': 'non_field_errors',
      },
    ],
  };

  Map<String, dynamic> _mapDioError(DioException exception) =>
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
