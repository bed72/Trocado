import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expenses_page_model.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

abstract interface class IExpenseRepository {
  Future<Either<Failure, ExpenseModel>> create({
    required int date,
    required int value,
    required String description,
  });

  // TODO miotos dados
  Future<Either<Failure, ExpenseModel>> update({
    required int id,
    required int date,
    required int value,
    required String description,
  });

  Future<Either<Failure, void>> delete({required int id});

  Future<Either<Failure, ExpensesPageModel>> findAll({
    String? cursor,
    ExpenseFilterModel? filter,
  });

  Future<Either<Failure, List<ExpenseModel>>> findRecent({int limit = 6});
}
