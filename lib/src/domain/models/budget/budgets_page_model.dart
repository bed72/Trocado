import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';

final class BudgetsPageModel extends Equatable {
  final String? nextCursor;
  final String? previousCursor;
  final List<BudgetModel> budgets;

  const BudgetsPageModel({
    this.nextCursor,
    this.previousCursor,
    this.budgets = const [],
  });

  BudgetsPageModel copyWith({
    String? nextCursor,
    String? previousCursor,
    List<BudgetModel>? budgets,
  }) => BudgetsPageModel(
    budgets: budgets ?? this.budgets,
    nextCursor: nextCursor ?? this.nextCursor,
    previousCursor: previousCursor ?? this.previousCursor,
  );

  @override
  List<Object?> get props => [budgets, nextCursor, previousCursor];
}
