import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';

import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/expense_request.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/expense/expense_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/expense/expenses_response.dart';

abstract interface class IRemoteExpenseDataSource {
  Future<Either<FailureResponse, ExpenseResponse>> create({
    required int date,
    required int value,
    required String description,
  });

  Future<Either<FailureResponse, ExpensesResponse>> findRecent({
    required int limit,
  });

  Future<Either<FailureResponse, ExpensesResponse>> findAll({String? cursor});
}

final class RemoteExpenseDataSource implements IRemoteExpenseDataSource {
  final IHttpClient _client;

  RemoteExpenseDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, ExpenseResponse>> create({
    required int date,
    required int value,
    required String description,
  }) async {
    final response = await _client.post(
      parameter: Requests(
        EndpointKey.expenses.path,
        body: ExpenseRequest(
          date: date,
          value: value,
          description: description,
        ).toJson(),
      ),
    );

    return response.either(FailureResponse.fromJson, ExpenseResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, ExpensesResponse>> findRecent({
    required int limit,
  }) async {
    final response = await _client.get(
      parameter: Requests(EndpointKey.expenses.path),
    );

    return response.either(FailureResponse.fromJson, ExpensesResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, ExpensesResponse>> findAll({
    String? cursor,
  }) async {
    final response = await _client.get(
      parameter: Requests(
        EndpointKey.expenses.path,
        query: cursor == null ? null : {'cursor': cursor},
      ),
    );

    return response.either(FailureResponse.fromJson, ExpensesResponse.fromJson);
  }
}
