import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';

import 'package:trocado/src/domain/models/page_model.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

abstract interface class IExpenseRepository {
  Future<Either<Failure, void>> delete({required int id});
  Future<Either<Failure, ExpenseModel>> findById({required int id});
  Future<Either<Failure, List<ExpenseModel>>> findRecent({
    int limit = 6,
    required FinancialScopeEnum scope,
  });
  Future<Either<Failure, ExpenseModel>> create({
    required int date,
    required int value,
    required String description,
  });
  Future<Either<Failure, PageModel<ExpenseModel>>> findAll({
    required FinancialScopeEnum scope,
    String? cursor,
    ExpenseFilterModel? filter,
  });
  Future<Either<Failure, ExpenseModel>> update({
    required int id,
    required int date,
    required int value,
    required String description,
  });
}
