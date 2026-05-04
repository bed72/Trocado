import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

abstract interface class IRemoteUserDataSource {
  Future<Either<FailureResponse, UserResponse>> me();

  Future<Either<FailureResponse, void>> deactivate({required String refresh});
}

final class RemoteUserDataSource implements IRemoteUserDataSource {
  final IHttpClient _client;

  RemoteUserDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, UserResponse>> me() async {
    final response = await _client.get(
      parameter: Requests(EndpointKey.me.path),
    );

    return response.either(FailureResponse.fromJson, UserResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, void>> deactivate({
    required String refresh,
  }) async {
    final response = await _client.delete(
      parameter: Requests(EndpointKey.me.path, body: {'refresh': refresh}),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }
}
