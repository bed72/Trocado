import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/budget_model.dart';

abstract interface class IBudgetRepository {
  Future<Either<Failure, BudgetModel>> create({
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  });
}
