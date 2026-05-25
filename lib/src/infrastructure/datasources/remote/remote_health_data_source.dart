import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/health/health_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

abstract interface class IRemoteHealthDataSource {
  Future<Either<FailureResponse, HealthResponse>> check();
}

final class RemoteHealthDataSource implements IRemoteHealthDataSource {
  final IHttpClient _client;

  RemoteHealthDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, HealthResponse>> check() async {
    final response = await _client.get(
      parameter: Requests('${EndpointKey.health.path}?format=json'),
    );

    return response.either(FailureResponse.fromJson, HealthResponse.fromJson);
  }
}
