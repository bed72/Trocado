import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';

import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/sign_in_request.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/sign_in_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

abstract interface class IRemoteAuthenticationDataSource {
  Future<Either<FailureResponse, SignInResponse>> signIn({
    required SignInRequest parameter,
  });
}

final class RemoteAuthenticationDataSource
    implements IRemoteAuthenticationDataSource {
  final IHttpClient _client;

  RemoteAuthenticationDataSource({required IHttpClient client})
    : _client = client;

  @override
  Future<Either<FailureResponse, SignInResponse>> signIn({
    required SignInRequest parameter,
  }) async {
    final response = await _client.post(
      parameter: Requests(EndpointKey.signIn.path, body: parameter.toJson()),
    );

    return response.either(FailureResponse.fromJson, SignInResponse.fromJson);
  }
}
