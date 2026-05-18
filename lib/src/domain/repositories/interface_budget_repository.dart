import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/models/budget/budgets_page_model.dart';
import 'package:trocado/src/domain/models/budget/active_budget_model.dart';

abstract interface class IBudgetRepository {
  Future<Either<Failure, void>> delete({required int id});
  Future<Either<Failure, ActiveBudgetModel?>> findActive();
  Future<Either<Failure, BudgetModel>> findById({required int id});
  Future<Either<Failure, BudgetsPageModel>> findAll({String? cursor});
  Future<Either<Failure, BudgetModel>> create({
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  });
  Future<Either<Failure, BudgetModel>> update({
    required int id,
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  });
}
