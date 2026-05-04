import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/budget_request.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/budget/budget_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/budget/budgets_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/budget/active_budget_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

abstract interface class IRemoteBudgetDataSource {
  Future<Either<FailureResponse, ActiveBudgetResponse>> findActive();

  Future<Either<FailureResponse, BudgetsResponse>> findAll({String? cursor});

  Future<Either<FailureResponse, BudgetResponse>> findById({required int id});

  // TODO muitos dados
  Future<Either<FailureResponse, BudgetResponse>> create({
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  });

  Future<Either<FailureResponse, BudgetResponse>> update({
    required int id,
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  });

  Future<Either<FailureResponse, void>> delete({required int id});
}

final class RemoteBudgetDataSource implements IRemoteBudgetDataSource {
  final IHttpClient _client;

  RemoteBudgetDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, ActiveBudgetResponse>> findActive() async {
    final response = await _client.get(
      parameter: Requests(EndpointKey.budgetsActive.path),
    );

    return response.either(
      FailureResponse.fromJson,
      ActiveBudgetResponse.fromJson,
    );
  }

  @override
  Future<Either<FailureResponse, BudgetsResponse>> findAll({
    String? cursor,
  }) async {
    final response = await _client.get(
      parameter: Requests(
        EndpointKey.budgets.path,
        query: cursor == null ? null : {'cursor': cursor},
      ),
    );

    return response.either(FailureResponse.fromJson, BudgetsResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, BudgetResponse>> findById({
    required int id,
  }) async {
    final response = await _client.get(
      parameter: Requests('${EndpointKey.budgets.path}/$id'),
    );

    return response.either(FailureResponse.fromJson, BudgetResponse.fromJson);
  }

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

  @override
  Future<Either<FailureResponse, BudgetResponse>> update({
    required int id,
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  }) async {
    final response = await _client.patch(
      parameter: Requests(
        '${EndpointKey.budgets.path}/$id',
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

  @override
  Future<Either<FailureResponse, void>> delete({required int id}) async {
    final response = await _client.delete(
      parameter: Requests('${EndpointKey.budgets.path}/$id'),
    );

    return response.either<FailureResponse, void>(
      FailureResponse.fromJson,
      (_) {},
    );
  }
}
