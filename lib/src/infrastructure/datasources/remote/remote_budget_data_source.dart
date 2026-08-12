import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/budget_request.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/budget/budget_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/budget/active_budget_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/budget/shared_active_budget_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/reponses.dart';

abstract interface class IRemoteBudgetDataSource {
  Future<Either<FailureResponse, DataModel<ActiveBudgetResponse>>> findActive();

  Future<Either<FailureResponse, DataModel<SharedActiveBudgetResponse>>>
  findActiveShared();

  Future<Either<FailureResponse, DataModel<List<BudgetResponse>>>> findAll({
    String? cursor,
  });

  Future<Either<FailureResponse, DataModel<BudgetResponse>>> findById({
    required int id,
  });

  Future<Either<FailureResponse, DataModel<BudgetResponse>>> create({
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  });

  Future<Either<FailureResponse, DataModel<BudgetResponse>>> update({
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

  RemoteBudgetDataSource({required this._client});

  @override
  Future<Either<FailureResponse, DataModel<ActiveBudgetResponse>>>
  findActive() async {
    final response = await _client.get(
      parameter: Requests(EndpointKey.budgetsActive.path),
    );

    return response.toDataModel(
      (data) =>
          ActiveBudgetResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Either<FailureResponse, DataModel<SharedActiveBudgetResponse>>>
  findActiveShared() async {
    final response = await _client.get(
      parameter: Requests(EndpointKey.budgetsActiveShared.path),
    );

    return response.toDataModel(
      (data) => SharedActiveBudgetResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  @override
  Future<Either<FailureResponse, DataModel<List<BudgetResponse>>>> findAll({
    String? cursor,
  }) async {
    final response = await _client.get(
      parameter: Requests(
        EndpointKey.budgets.path,
        query: cursor == null ? null : {'cursor': cursor},
      ),
    );

    return response.toDataModel(
      (data) => (data as List)
          .map(
            (item) =>
                BudgetResponse.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<Either<FailureResponse, DataModel<BudgetResponse>>> findById({
    required int id,
  }) async {
    final response = await _client.get(
      parameter: Requests('${EndpointKey.budgets.path}/$id'),
    );

    return response.toDataModel(
      (data) => BudgetResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Either<FailureResponse, DataModel<BudgetResponse>>> create({
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

    return response.toDataModel(
      (data) => BudgetResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Either<FailureResponse, DataModel<BudgetResponse>>> update({
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

    return response.toDataModel(
      (data) => BudgetResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
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
