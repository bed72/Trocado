import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/expense/expense_response.dart';

List<ExpenseResponse> _expenses(Object? json) => (json as List)
    .map(
      (item) =>
          ExpenseResponse.fromJson(Map<String, dynamic>.from(item as Map)),
    )
    .toList();

void main() {
  test('parses every item from data', () {
    final data = DataModel<List<ExpenseResponse>>.fromJson(const {
      'data': [
        {
          'id': 129,
          'value': '85.50',
          'date': '2026-04-15',
          'category': 'food',
          'description': 'Cafezinho',
          'created_at': '2026-04-22T11:45:03.220605-03:00',
        },
        {
          'id': 112,
          'value': '38.91',
          'date': '2026-04-30',
          'category': 'health',
          'description': 'Farmácia',
          'created_at': '2026-04-22T11:29:22.128274-03:00',
        },
      ],
    }, _expenses);

    expect(data.data, hasLength(2));
    expect(data.data.first.id, 129);
    expect(data.data.last.id, 112);
  });
}
