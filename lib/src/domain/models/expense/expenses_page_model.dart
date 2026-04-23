import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';

final class ExpensesPageModel extends Equatable {
  final String? nextCursor;
  final String? previousCursor;
  final List<ExpenseModel> expenses;

  const ExpensesPageModel({
    this.nextCursor,
    this.previousCursor,
    this.expenses = const [],
  });

  ExpensesPageModel copyWith({
    String? nextCursor,
    String? previousCursor,
    List<ExpenseModel>? expenses,
  }) => ExpensesPageModel(
    expenses: expenses ?? this.expenses,
    nextCursor: nextCursor ?? this.nextCursor,
    previousCursor: previousCursor ?? this.previousCursor,
  );

  @override
  List<Object?> get props => [expenses, nextCursor, previousCursor];
}
