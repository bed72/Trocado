import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/models/budget_model.dart';
import 'package:trocado/src/domain/models/budget_summary_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

class GetBudgetSummary {
  final IExpenseRepository _expenseRepo;

  GetBudgetSummary({required IExpenseRepository expenseRepository})
      : _expenseRepo = expenseRepository;

  Either<String, BudgetSummaryModel> call(BudgetModel budget) {
    final result = _expenseRepo.findByPeriod(
      startAt: budget.startDate,
      endAt: budget.endDate,
    );

    return result.mapRight((expenses) {
      final spent = expenses.fold(0.0, (sum, e) => sum + e.amount);
      return BudgetSummaryModel(budget: budget, spent: spent);
    });
  }
}
