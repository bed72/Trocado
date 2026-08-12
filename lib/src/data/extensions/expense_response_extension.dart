import 'package:intl/intl.dart';

import 'package:trocado/src/domain/models/page_model.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/expense/expense_response.dart';

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

extension ExpensesResponseExtension on DataModel<List<ExpenseResponse>> {
  List<ExpenseModel> toModel({int? limit}) {
    final items = data.map((item) => item.toModel()).toList();

    return limit == null ? items : items.take(limit).toList();
  }

  PageModel<ExpenseModel> toPageModel() => PageModel<ExpenseModel>(
    nextCursor: _cursorFrom(links?['next'], 'next_cursor'),
    previousCursor: _cursorFrom(
      links?['previous'] ?? links?['prev'],
      'previous_cursor',
    ),
    items: data.map((item) => item.toModel()).toList(),
  );

  String? _cursorFrom(Object? link, String metaKey) {
    final String? url = link as String?;
    final String? cursor = url == null
        ? null
        : Uri.parse(url).queryParameters['cursor'];
    if (cursor != null) return cursor;

    final pagination = meta?['pagination'];
    if (pagination is! Map) return null;

    return pagination[metaKey] as String?;
  }
}
