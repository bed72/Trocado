import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';

abstract interface class IBudgetRepository {
  Either<String, void> deleteById(int id);
  Either<String, List<BudgetModel>> findAll();
  Either<String, void> upsert(BudgetModel model);
  Either<String, BudgetModel?> findActive(int currentDate);
}
