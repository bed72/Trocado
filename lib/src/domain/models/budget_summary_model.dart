import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/budget_model.dart';

final class BudgetSummaryModel extends Equatable {
  final BudgetModel budget;
  final double spent;

  const BudgetSummaryModel({required this.budget, required this.spent});

  double get remaining => budget.amount - spent;
  double get percentage => budget.amount > 0 ? spent / budget.amount : 0;
  bool get isOverBudget => spent > budget.amount;

  @override
  List<Object?> get props => [budget, spent];
}
