import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';

final class BudgetSummaryModel extends Equatable {
  final double spent;
  final BudgetModel budget;

  const BudgetSummaryModel({required this.budget, required this.spent});

  double get remaining => budget.amount - spent;
  bool get isOverBudget => spent > budget.amount;
  double get percentage => budget.amount > 0 ? spent / budget.amount : 0;

  @override
  List<Object?> get props => [spent, budget];
}
