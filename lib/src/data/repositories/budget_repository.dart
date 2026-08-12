import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/page_model.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/models/budget/active_budget_model.dart';
import 'package:trocado/src/domain/models/budget/shared_active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/data/extensions/failure_response_extension.dart';
import 'package:trocado/src/data/extensions/budget/budget_response_extension.dart';
import 'package:trocado/src/data/extensions/budget/budgets_response_extension.dart';
import 'package:trocado/src/data/extensions/budget/active_budget_response_extension.dart';
import 'package:trocado/src/data/extensions/budget/shared_active_budget_response_extension.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_budget_data_source.dart';

final class BudgetRepository implements IBudgetRepository {
  final IRemoteBudgetDataSource _dataSource;

  BudgetRepository({required this._dataSource});

  @override
  Future<Either<Failure, ActiveBudgetModel?>> findActive() async {
    final response = await _dataSource.findActive();

    if (response.isLeft) {
      final failure = response.left.toFailure();
      return failure is NotFoundFailure ? const Right(null) : Left(failure);
    }

    return Right(response.right.data.toModel());
  }

  @override
  Future<Either<Failure, SharedActiveBudgetModel?>> findActiveShared() async {
    final response = await _dataSource.findActiveShared();

    if (response.isLeft) {
      final failure = response.left.toFailure();
      return failure is NotFoundFailure ? const Right(null) : Left(failure);
    }

    return Right(response.right.data.toModel());
  }

  @override
  Future<Either<Failure, PageModel<BudgetModel>>> findAll({
    String? cursor,
  }) async {
    final response = await _dataSource.findAll(cursor: cursor);

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.toPageModel(),
    );
  }

  @override
  Future<Either<Failure, BudgetModel>> findById({required int id}) async {
    final response = await _dataSource.findById(id: id);

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.toModel(),
    );
  }

  @override
  Future<Either<Failure, BudgetModel>> create({
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  }) async {
    final response = await _dataSource.create(
      value: value,
      endDate: endDate,
      startDate: startDate,
      description: description,
    );

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.toModel(),
    );
  }

  @override
  Future<Either<Failure, BudgetModel>> update({
    required int id,
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  }) async {
    final response = await _dataSource.update(
      id: id,
      value: value,
      endDate: endDate,
      startDate: startDate,
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
}
