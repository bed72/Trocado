import 'package:trocado/src/infrastructure/clients/http/responses/budget/budget_response.dart';

final class BudgetsResponse {
  final String? next;
  final String? previous;
  final List<BudgetResponse> budgets;

  const BudgetsResponse({
    required this.budgets,
    this.next,
    this.previous,
  });

  factory BudgetsResponse.fromJson(Map<String, dynamic> json) =>
      BudgetsResponse(
        next: json['next'] as String?,
        previous: json['previous'] as String?,
        budgets: (json['results'] as List)
            .map(
              (item) => BudgetResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}
