import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/models/expense_model.dart';

abstract interface class IExpenseRepository {
  Either<String, void> deleteById(int id);
  Either<String, ExpenseModel> findById(int id);
  Either<String, void> upsert(ExpenseModel model);
  Either<String, List<ExpenseModel>> findByPeriod({
    int? limit,
    int? offset,
    int? startAt,
    int? endAt,
  });
}
