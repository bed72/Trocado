import 'package:trocado/src/core/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expenses_page_model.dart';

abstract interface class IExpenseRepository {
  Future<Either<Failure, ExpenseModel>> create({
    required int date,
    required int value,
    required String description,
  });

  Future<Either<Failure, List<ExpenseModel>>> findRecent({int limit = 4});

  Future<Either<Failure, ExpensesPageModel>> findAll({String? cursor});
}
