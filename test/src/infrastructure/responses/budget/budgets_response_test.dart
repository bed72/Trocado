import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/budget/budget_response.dart';

List<BudgetResponse> _budgets(Object? json) => (json as List)
    .map(
      (item) => BudgetResponse.fromJson(Map<String, dynamic>.from(item as Map)),
    )
    .toList();

void main() {
  test('parses data and preserves meta and links', () {
    final data = DataModel<List<BudgetResponse>>.fromJson(const {
      'data': [
        {
          'id': 9,
          'value': '1000.00',
          'remaining': '714.50',
          'total_spent': '285.50',
          'end_date': '2026-05-30',
          'start_date': '2026-05-01',
          'description': 'May budget',
          'created_at': '2026-05-02T17:58:42.119430-03:00',
        },
      ],
      'meta': {
        'pagination': {'next_cursor': 'abc'},
      },
      'links': {'self': '/v1/budgets', 'next': '/v1/budgets?cursor=abc'},
    }, _budgets);

    expect(data.data, hasLength(1));
    expect(data.data.first.id, 9);
    expect(data.meta?['pagination']['next_cursor'], 'abc');
    expect(data.links?['self'], '/v1/budgets');
    expect(data.links?['next'], '/v1/budgets?cursor=abc');
  });

  test('parses an empty collection', () {
    final data = DataModel<List<BudgetResponse>>.fromJson(const {
      'data': <dynamic>[],
    }, _budgets);

    expect(data.data, isEmpty);
  });
}
