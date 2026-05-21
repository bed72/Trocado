import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/models/budget/budgets_page_model.dart';
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

  BudgetRepository({required IRemoteBudgetDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, ActiveBudgetModel?>> findActive() async {
    final data = await _dataSource.findActive();

    if (data.isLeft) {
      final failure = data.left.toFailure();
      return failure is NotFoundFailure ? const Right(null) : Left(failure);
    }

    return Right(data.right.toModel());
  }

  @override
  Future<Either<Failure, SharedActiveBudgetModel?>> findActiveShared() async {
    final data = await _dataSource.findActiveShared();

    if (data.isLeft) {
      final failure = data.left.toFailure();
      return failure is NotFoundFailure ? const Right(null) : Left(failure);
    }

    return Right(data.right.toModel());
  }

  @override
  Future<Either<Failure, BudgetsPageModel>> findAll({String? cursor}) async {
    final data = await _dataSource.findAll(cursor: cursor);

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toPageModel(),
    );
  }

  @override
  Future<Either<Failure, BudgetModel>> findById({required int id}) async {
    final data = await _dataSource.findById(id: id);

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }

  @override
  Future<Either<Failure, BudgetModel>> create({
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  }) async {
    final data = await _dataSource.create(
      value: value,
      endDate: endDate,
      startDate: startDate,
      description: description,
    );

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
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
    final data = await _dataSource.update(
      id: id,
      value: value,
      endDate: endDate,
      startDate: startDate,
      description: description,
    );

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }

  @override
  Future<Either<Failure, void>> delete({required int id}) async {
    final data = await _dataSource.delete(id: id);

    return data.either<Failure, void>((failure) => failure.toFailure(), (_) {});
  }
}
