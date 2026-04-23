import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/expense/expenses_response.dart';

const _json = {
  'next': 'http://api/expenses?cursor=abc',
  'previous': null,
  'results': [
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
};

void main() {
  group('ExpensesResponse.fromJson', () {
    test('parses results array into ExpenseResponse list', () {
      final response = ExpensesResponse.fromJson(_json);

      expect(response.expenses, hasLength(2));
      expect(response.expenses.first.id, 129);
      expect(response.expenses.first.category, 'food');
      expect(response.expenses.first.description, 'Cafezinho');
      expect(response.expenses.last.id, 112);
      expect(response.expenses.last.category, 'health');
    });

    test('exposes next as the raw url when provided', () {
      final response = ExpensesResponse.fromJson(_json);

      expect(response.next, 'http://api/expenses?cursor=abc');
    });

    test('exposes previous as null when the backend omits it', () {
      final response = ExpensesResponse.fromJson(_json);

      expect(response.previous, isNull);
    });

    test('exposes both cursors when both are provided', () {
      final response = ExpensesResponse.fromJson(const {
        'next': 'http://api/expenses?cursor=ABC',
        'previous': 'http://api/expenses?cursor=XYZ',
        'results': [],
      });

      expect(response.next, 'http://api/expenses?cursor=ABC');
      expect(response.previous, 'http://api/expenses?cursor=XYZ');
    });

    test('exposes both cursors as null when both are null', () {
      final response = ExpensesResponse.fromJson(const {
        'next': null,
        'previous': null,
        'results': [],
      });

      expect(response.next, isNull);
      expect(response.previous, isNull);
    });

    test('parses empty results array into empty list', () {
      final response = ExpensesResponse.fromJson(const {
        'next': null,
        'previous': null,
        'results': [],
      });

      expect(response.expenses, isEmpty);
    });
  });
}
