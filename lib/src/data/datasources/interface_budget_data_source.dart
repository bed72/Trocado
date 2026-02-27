import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/database/entities/budget_entity.dart';

abstract interface class IBudgetDataSource {
  Either<String, void> upsert(BudgetEntity entity);
  Either<String, BudgetEntity?> findActive(int currentDate);
  Either<String, List<BudgetEntity>> findAll();
  Either<String, void> deleteById(int id);
}
