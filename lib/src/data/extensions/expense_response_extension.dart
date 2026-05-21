import 'package:intl/intl.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expenses_page_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/expense/expense_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/expense/expenses_response.dart';

extension ExpenseResponseExtension on ExpenseResponse {
  ExpenseModel toModel() => ExpenseModel(
    id: id,
    description: description,
    createdByMe: createdByMe,
    createdByName: createdByName,
    category: .fromString(category),
    value: (double.parse(value) * 100).round(),
    createdAt: DateTime.parse(createdAt).millisecondsSinceEpoch,
    date: DateFormat('yyyy-MM-dd').parse(date).millisecondsSinceEpoch,
  );
}

extension ExpensesResponseExtension on ExpensesResponse {
  List<ExpenseModel> toModel({int? limit}) {
    final items = expenses.map((item) => item.toModel()).toList();

    return limit == null ? items : items.take(limit).toList();
  }

  ExpensesPageModel toPageModel() => ExpensesPageModel(
    nextCursor: _cursorFrom(next),
    previousCursor: _cursorFrom(previous),
    expenses: expenses.map((item) => item.toModel()).toList(),
  );

  String? _cursorFrom(String? url) {
    if (url == null) return null;

    return Uri.parse(url).queryParameters['cursor'];
  }
}
