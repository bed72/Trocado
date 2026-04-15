import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/me_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

abstract interface class IRemoteUserDataSource {
  Future<Either<FailureResponse, MeResponse>> me();
}

final class RemoteUserDataSource implements IRemoteUserDataSource {
  final IHttpClient _client;

  RemoteUserDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, MeResponse>> me() async {
    final response = await _client.get(
      parameter: Requests(EndpointKey.me.path),
    );

    return response.either(FailureResponse.fromJson, MeResponse.fromJson);
  }
}
