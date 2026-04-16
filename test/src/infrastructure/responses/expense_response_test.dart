import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/expense_response.dart';

void main() {
  group('ExpenseResponse.fromJson', () {
    test('parses all fields correctly', () {
      final response = ExpenseResponse.fromJson({
        'id': 1,
        'value': '85.50',
        'date': '2026-03-15',
        'description': 'Mercado',
      });

      expect(response.id, 1);
      expect(response.value, '85.50');
      expect(response.date, '2026-03-15');
      expect(response.description, 'Mercado');
    });

    test('parses zero-decimal value', () {
      final response = ExpenseResponse.fromJson({
        'id': 2,
        'value': '100.00',
        'date': '2026-01-01',
        'description': 'Aluguel',
      });

      expect(response.value, '100.00');
    });

    test('parses description with special characters', () {
      final response = ExpenseResponse.fromJson({
        'id': 3,
        'value': '12.90',
        'date': '2026-03-15',
        'description': 'Café da manhã',
      });

      expect(response.description, 'Café da manhã');
    });
  });
}
