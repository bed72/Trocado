import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/expense_model.dart';

enum ExpenseListStatus { initial, loading, loaded, error }

final class ExpenseListState extends Equatable {
  final List<ExpenseModel> expenses;
  final ExpenseListStatus status;
  final bool hasReachedMax;
  final int page;
  final String? errorMessage;

  const ExpenseListState({
    this.page = 0,
    this.errorMessage,
    this.expenses = const [],
    this.hasReachedMax = false,
    this.status = ExpenseListStatus.initial,
  });

  double get totalAmount => expenses.fold(0, (sum, e) => sum + e.amount);

  ExpenseListState copyWith({
    int? page,
    String? errorMessage,
    bool? hasReachedMax,
    ExpenseListStatus? status,
    List<ExpenseModel>? expenses,
  }) => ExpenseListState(
    page: page ?? this.page,
    status: status ?? this.status,
    expenses: expenses ?? this.expenses,
    errorMessage: errorMessage ?? this.errorMessage,
    hasReachedMax: hasReachedMax ?? this.hasReachedMax,
  );

  @override
  List<Object?> get props => [expenses, status, hasReachedMax, page, errorMessage];
}
