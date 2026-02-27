import 'package:equatable/equatable.dart';

import 'package:trocado/src/presentation/data/expense_presentation_data.dart';

enum ExpenseListStatus { initial, loading, loaded, failure }

final class ExpenseListState extends Equatable {
  final int page;
  final bool hasReachedMax;
  final String? failureMessage;
  final ExpenseListStatus status;
  final List<ExpensePresentationData> expenses;

  const ExpenseListState({
    this.page = 0,
    this.failureMessage,
    this.status = .initial,
    this.expenses = const [],
    this.hasReachedMax = false,
  });

  double get totalAmount =>
      expenses.fold(0, (sum, expense) => sum + expense.amount);

  ExpenseListState copyWith({
    int? page,
    bool? hasReachedMax,
    String? failureMessage,
    ExpenseListStatus? status,
    List<ExpensePresentationData>? expenses,
  }) => ExpenseListState(
    page: page ?? this.page,
    status: status ?? this.status,
    expenses: expenses ?? this.expenses,
    hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    failureMessage: failureMessage ?? this.failureMessage,
  );

  @override
  List<Object?> get props => [
    page,
    status,
    expenses,
    hasReachedMax,
    failureMessage,
  ];
}
