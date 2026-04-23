import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/insight/insights_response.dart';

abstract interface class IRemoteInsightsDataSource {
  Future<Either<FailureResponse, InsightsResponse>> findAll();
}

final class RemoteInsightsDataSource implements IRemoteInsightsDataSource {
  final IHttpClient _client;

  RemoteInsightsDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, InsightsResponse>> findAll() async {
    final response = await _client.get(
      parameter: Requests(EndpointKey.insights.path),
    );

    return response.either(FailureResponse.fromJson, InsightsResponse.fromJson);
  }
}
