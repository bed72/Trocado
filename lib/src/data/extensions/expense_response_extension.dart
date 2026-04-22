import 'package:intl/intl.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/expense/expense_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/expense/expenses_response.dart';

extension ExpenseResponseExtension on ExpenseResponse {
  ExpenseModel toModel() => ExpenseModel(
    id: id,
    description: description,
    category: .fromString(category),
    value: (double.parse(value) * 100).round(),
    date: DateFormat('yyyy-MM-dd').parse(date).millisecondsSinceEpoch,
    createdAt: DateTime.parse(createdAt).millisecondsSinceEpoch,
  );
}

extension ExpensesResponseExtension on ExpensesResponse {
  List<ExpenseModel> toModel({int? limit}) {
    final items = expenses.map((item) => item.toModel()).toList();

    return limit == null ? items : items.take(limit).toList();
  }
}
