import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/extensions/expense_response_extension.dart';
import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/page_model.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_expense_data_source.dart';

final class ExpenseRepository implements IExpenseRepository {
  final IRemoteExpenseDataSource _dataSource;

  ExpenseRepository({required this._dataSource});

  @override
  Future<Either<Failure, ExpenseModel>> create({
    required int date,
    required int value,
    required String description,
  }) async {
    final response = await _dataSource.create(
      date: date,
      value: value,
      description: description,
    );

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.toModel(),
    );
  }

  @override
  Future<Either<Failure, ExpenseModel>> findById({required int id}) async {
    final response = await _dataSource.findById(id: id);

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.toModel(),
    );
  }

  @override
  Future<Either<Failure, ExpenseModel>> update({
    required int id,
    required int date,
    required int value,
    required String description,
  }) async {
    final response = await _dataSource.update(
      id: id,
      date: date,
      value: value,
      description: description,
    );

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.toModel(),
    );
  }

  @override
  Future<Either<Failure, void>> delete({required int id}) async {
    final response = await _dataSource.delete(id: id);

    return response.either<Failure, void>(
      (failure) => failure.toFailure(),
      (_) {},
    );
  }

  @override
  Future<Either<Failure, List<ExpenseModel>>> findRecent({
    int limit = 6,
    required FinancialScopeEnum scope,
  }) async {
    final response = await _dataSource.findRecent(limit: limit, scope: scope);

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.toModel(limit: limit),
    );
  }

  @override
  Future<Either<Failure, PageModel<ExpenseModel>>> findAll({
    required FinancialScopeEnum scope,
    String? cursor,
    ExpenseFilterModel? filter,
  }) async {
    final response = await _dataSource.findAll(
      scope: scope,
      cursor: cursor,
      filter: filter,
    );

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.toPageModel(),
    );
  }
}
