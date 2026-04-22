import 'package:trocado/src/infrastructure/clients/http/responses/expense/expense_response.dart';

final class ExpensesResponse {
  final List<ExpenseResponse> expenses;

  const ExpensesResponse({required this.expenses});

  factory ExpensesResponse.fromJson(Map<String, dynamic> json) =>
      ExpensesResponse(
        expenses: (json['results'] as List)
            .map(
              (item) => ExpenseResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}
