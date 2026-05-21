import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/insight/insights_response.dart';

abstract interface class IRemoteInsightsDataSource {
  Future<Either<FailureResponse, InsightsResponse>> findAll({
    required FinancialScopeEnum scope,
  });
}

final class RemoteInsightsDataSource implements IRemoteInsightsDataSource {
  final IHttpClient _client;

  RemoteInsightsDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, InsightsResponse>> findAll({
    required FinancialScopeEnum scope,
  }) async {
    final response = await _client.get(parameter: Requests(_path(scope)));

    return response.either(FailureResponse.fromJson, InsightsResponse.fromJson);
  }

  String _path(FinancialScopeEnum scope) => switch (scope) {
    .mine => EndpointKey.insights.path,
    .couple => EndpointKey.insightsShared.path,
  };
}
