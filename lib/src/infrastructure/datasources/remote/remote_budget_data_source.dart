import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/budget_request.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/budget_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

abstract interface class IRemoteBudgetDataSource {
  Future<Either<FailureResponse, BudgetResponse>> create({
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  });
}

final class RemoteBudgetDataSource implements IRemoteBudgetDataSource {
  final IHttpClient _client;

  RemoteBudgetDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, BudgetResponse>> create({
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  }) async {
    final response = await _client.post(
      parameter: Requests(
        EndpointKey.budgets.path,
        body: BudgetRequest(
          value: value,
          endDate: endDate,
          startDate: startDate,
          description: description,
        ).toJson(),
      ),
    );

    return response.either(FailureResponse.fromJson, BudgetResponse.fromJson);
  }
}
