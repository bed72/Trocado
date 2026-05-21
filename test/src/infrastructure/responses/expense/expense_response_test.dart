import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/expense/expense_response.dart';

void main() {
  group('ExpenseResponse.fromJson', () {
    test('parses all fields correctly', () {
      final response = ExpenseResponse.fromJson({
        'id': 1,
        'value': '85.50',
        'date': '2026-03-15',
        'category': 'food',
        'description': 'Mercado',
        'created_at': '2026-03-15T11:45:03.220605-03:00',
      });

      expect(response.id, 1);
      expect(response.value, '85.50');
      expect(response.date, '2026-03-15');
      expect(response.category, 'food');
      expect(response.description, 'Mercado');
      expect(response.createdAt, '2026-03-15T11:45:03.220605-03:00');
    });

    test('parses zero-decimal value', () {
      final response = ExpenseResponse.fromJson({
        'id': 2,
        'value': '100.00',
        'date': '2026-01-01',
        'category': 'housing',
        'description': 'Aluguel',
        'created_at': '2026-01-01T08:00:00Z',
      });

      expect(response.value, '100.00');
      expect(response.category, 'housing');
    });

    test('parses description with special characters', () {
      final response = ExpenseResponse.fromJson({
        'id': 3,
        'value': '12.90',
        'date': '2026-03-15',
        'category': 'food',
        'description': 'Café da manhã',
        'created_at': '2026-03-15T08:30:00Z',
      });

      expect(response.description, 'Café da manhã');
    });

    test('preserves unknown category string', () {
      final response = ExpenseResponse.fromJson({
        'id': 4,
        'value': '20.00',
        'date': '2026-03-15',
        'category': 'travel',
        'description': 'Uber',
        'created_at': '2026-03-15T08:30:00Z',
      });

      expect(response.category, 'travel');
    });

    test('parses created_by_me and created_by_name when present', () {
      final response = ExpenseResponse.fromJson({
        'id': 5,
        'value': '50.00',
        'date': '2026-05-19',
        'category': 'food',
        'description': 'Cafezinho',
        'created_at': '2026-05-19T15:09:04Z',
        'created_by_me': false,
        'created_by_name': 'Gabriel Ramos',
      });

      expect(response.createdByMe, isFalse);
      expect(response.createdByName, 'Gabriel Ramos');
    });

    test('created_by_me and created_by_name are null when absent', () {
      final response = ExpenseResponse.fromJson({
        'id': 6,
        'value': '20.00',
        'date': '2026-05-19',
        'category': 'food',
        'description': 'Padaria',
        'created_at': '2026-05-19T08:00:00Z',
      });

      expect(response.createdByMe, isNull);
      expect(response.createdByName, isNull);
    });
  });
}
