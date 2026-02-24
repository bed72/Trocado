import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/database/entities/expense_entity.dart';

abstract interface class IExpenseDataSource {
  Either<String, void> deleteById(int id);
  Either<String, ExpenseEntity> findById(int id);
  Either<String, void> upsert(ExpenseEntity entity);
  Either<String, List<ExpenseEntity>> findByPeriod({
    int? limit,
    int? offset,
    int? startAt,
    int? endAt,
  });
}
