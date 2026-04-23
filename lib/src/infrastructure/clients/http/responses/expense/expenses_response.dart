import 'package:trocado/src/infrastructure/clients/http/responses/expense/expense_response.dart';

final class ExpensesResponse {
  final String? next;
  final String? previous;
  final List<ExpenseResponse> expenses;

  const ExpensesResponse({
    required this.expenses,
    this.next,
    this.previous,
  });

  factory ExpensesResponse.fromJson(Map<String, dynamic> json) =>
      ExpensesResponse(
        next: json['next'] as String?,
        previous: json['previous'] as String?,
        expenses: (json['results'] as List)
            .map(
              (item) => ExpenseResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}
