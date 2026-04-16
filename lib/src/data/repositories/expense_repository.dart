import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/data/extensions/expense_response_extension.dart';
import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_expense_data_source.dart';

final class ExpenseRepository implements IExpenseRepository {
  final IRemoteExpenseDataSource _dataSource;

  ExpenseRepository({required IRemoteExpenseDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, ExpenseModel>> create({
    required int date,
    required int value,
    required String description,
  }) async {
    final data = await _dataSource.create(
      date: date,
      value: value,
      description: description,
    );

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }
}
