import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/budget_model.dart';
import 'package:trocado/src/domain/models/active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/data/extensions/budget_response_extension.dart';
import 'package:trocado/src/data/extensions/failure_response_extension.dart';
import 'package:trocado/src/data/extensions/active_budget_response_extension.dart';

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
}
