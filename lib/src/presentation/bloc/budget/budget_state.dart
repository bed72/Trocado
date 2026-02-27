import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/budget/budget_summary_model.dart';

enum BudgetStatus { initial, loading, active, empty, failure }

final class BudgetState extends Equatable {
  final BudgetStatus status;
  final String? failureMessage;
  final BudgetSummaryModel? summary;

  const BudgetState({
    this.summary,
    this.failureMessage,
    this.status = .initial,
  });

  BudgetState copyWith({
    BudgetStatus? status,
    String? failureMessage,
    BudgetSummaryModel? summary,
  }) => BudgetState(
    status: status ?? this.status,
    summary: summary ?? this.summary,
    failureMessage: failureMessage ?? this.failureMessage,
  );

  @override
  List<Object?> get props => [status, summary, failureMessage];
}
