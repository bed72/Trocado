import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/budget_summary_model.dart';

enum BudgetStatus { initial, loading, active, empty, error }

final class BudgetState extends Equatable {
  final BudgetSummaryModel? summary;
  final BudgetStatus status;
  final String? errorMessage;

  const BudgetState({
    this.summary,
    this.errorMessage,
    this.status = BudgetStatus.initial,
  });

  BudgetState copyWith({
    BudgetSummaryModel? summary,
    BudgetStatus? status,
    String? errorMessage,
  }) => BudgetState(
    summary: summary ?? this.summary,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [summary, status, errorMessage];
}
