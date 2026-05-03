import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';

final class BudgetItemPresentationData extends Equatable {
  final BudgetModel budget;
  final String formattedValue;
  final String formattedTotalSpent;
  final String formattedRemaining;
  final String formattedPeriod;

  const BudgetItemPresentationData({
    required this.budget,
    required this.formattedValue,
    required this.formattedTotalSpent,
    required this.formattedRemaining,
    required this.formattedPeriod,
  });

  @override
  List<Object?> get props => [
    budget,
    formattedValue,
    formattedTotalSpent,
    formattedRemaining,
    formattedPeriod,
  ];
}
