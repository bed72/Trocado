import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/application/use_cases/useca_case.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/models/budget/budget_summary_model.dart';

import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

class GetBudgetSummaryUseCase
    implements UsecaCase<BudgetModel, Either<String, BudgetSummaryModel>> {
  final IExpenseRepository _repository;

  GetBudgetSummaryUseCase({required IExpenseRepository repository})
    : _repository = repository;

  @override
  Either<String, BudgetSummaryModel> call(BudgetModel value) {
    final data = _repository.findByPeriod(
      endAt: value.endDate,
      startAt: value.startDate,
    );

    return data.mapRight((expenses) {
      final spent = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      return BudgetSummaryModel(budget: value, spent: spent);
    });
  }
}
