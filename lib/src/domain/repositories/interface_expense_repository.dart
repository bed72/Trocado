import 'package:trocado/src/core/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/expense_model.dart';

abstract interface class IExpenseRepository {
  Future<Either<Failure, ExpenseModel>> create({
    required int date,
    required int value,
    required String description,
  });
}
