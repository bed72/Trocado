import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';

import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/expense_request.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/expense_filter_request.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/expense/expense_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/expense/expenses_response.dart';

abstract interface class IRemoteExpenseDataSource {
  Future<Either<FailureResponse, ExpenseResponse>> create({
    required int date,
    required int value,
    required String description,
  });

  Future<Either<FailureResponse, ExpenseResponse>> findById({required int id});

  Future<Either<FailureResponse, ExpenseResponse>> update({
    required int id,
    required int date,
    required int value,
    required String description,
  });

  Future<Either<FailureResponse, void>> delete({required int id});

  Future<Either<FailureResponse, ExpensesResponse>> findRecent({
    required int limit,
    required FinancialScopeEnum scope,
  });

  Future<Either<FailureResponse, ExpensesResponse>> findAll({
    required FinancialScopeEnum scope,
    String? cursor,
    ExpenseFilterModel? filter,
  });
}

final class RemoteExpenseDataSource implements IRemoteExpenseDataSource {
  final IHttpClient _client;
  final ExpenseFilterRequest _request;

  RemoteExpenseDataSource({required this._client})
    : _request = const ExpenseFilterRequest();

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
  Future<Either<FailureResponse, ExpenseResponse>> findById({
    required int id,
  }) async {
    final response = await _client.get(
      parameter: Requests('${EndpointKey.expenses.path}/$id'),
    );

    return response.either(FailureResponse.fromJson, ExpenseResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, ExpenseResponse>> update({
    required int id,
    required int date,
    required int value,
    required String description,
  }) async {
    final response = await _client.patch(
      parameter: Requests(
        '${EndpointKey.expenses.path}/$id',
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
  Future<Either<FailureResponse, void>> delete({required int id}) async {
    final response = await _client.delete(
      parameter: Requests('${EndpointKey.expenses.path}/$id'),
    );

    return response.either<FailureResponse, void>(
      FailureResponse.fromJson,
      (_) {},
    );
  }

  @override
  Future<Either<FailureResponse, ExpensesResponse>> findRecent({
    required int limit,
    required FinancialScopeEnum scope,
  }) async {
    final response = await _client.get(parameter: Requests(_basePath(scope)));

    return response.either(FailureResponse.fromJson, ExpensesResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, ExpensesResponse>> findAll({
    required FinancialScopeEnum scope,
    String? cursor,
    ExpenseFilterModel? filter,
  }) async {
    final base = _basePath(scope);
    final rql = _request.build(filter: filter, cursor: cursor);
    final path = rql.isEmpty ? base : '$base?$rql';

    final response = await _client.get(parameter: Requests(path));

    return response.either(FailureResponse.fromJson, ExpensesResponse.fromJson);
  }

  String _basePath(FinancialScopeEnum scope) => switch (scope) {
    .mine => EndpointKey.expenses.path,
    .couple => EndpointKey.expensesShared.path,
  };
}
