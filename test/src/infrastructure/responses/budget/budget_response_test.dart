import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/budget/budget_response.dart';

void main() {
  group('BudgetResponse.fromJson', () {
    test('parses all fields correctly', () {
      const json = {
        'id': 1,
        'value': '1000.00',
        'end_date': '2026-03-31',
        'start_date': '2026-03-01',
        'description': 'March budget',
      };

      final response = BudgetResponse.fromJson(json);

      expect(response.id, 1);
      expect(response.value, '1000.00');
      expect(response.endDate, '2026-03-31');
      expect(response.startDate, '2026-03-01');
      expect(response.description, 'March budget');
    });

    test('parses decimal value with cents', () {
      const json = {
        'id': 2,
        'value': '85.50',
        'end_date': '2026-01-31',
        'start_date': '2026-01-01',
        'description': 'January budget',
      };

      final response = BudgetResponse.fromJson(json);

      expect(response.value, '85.50');
    });

    test('maps total_spent, remaining and created_at as raw strings', () {
      const json = {
        'id': 9,
        'value': '1000.00',
        'start_date': '2026-05-01',
        'end_date': '2026-05-30',
        'description': 'May budget',
        'total_spent': '285.50',
        'remaining': '714.50',
        'created_at': '2026-05-02T17:58:42.119430-03:00',
      };

      final response = BudgetResponse.fromJson(json);

      expect(response.totalSpent, '285.50');
      expect(response.remaining, '714.50');
      expect(response.createdAt, '2026-05-02T17:58:42.119430-03:00');
    });

    test('handles negative remaining string', () {
      const json = {
        'id': 4,
        'value': '2200.00',
        'start_date': '2026-02-01',
        'end_date': '2026-02-28',
        'description': 'Fevereiro 2026',
        'total_spent': '3934.97',
        'remaining': '-1734.97',
        'created_at': '2026-02-02T10:00:00Z',
      };

      final response = BudgetResponse.fromJson(json);

      expect(response.remaining, '-1734.97');
    });

    test(
      'maps total_spent, remaining and created_at to null when absent',
      () {
        const json = {
          'id': 1,
          'value': '1000.00',
          'start_date': '2026-03-01',
          'end_date': '2026-03-31',
          'description': 'March budget',
        };

        final response = BudgetResponse.fromJson(json);

        expect(response.totalSpent, isNull);
        expect(response.remaining, isNull);
        expect(response.createdAt, isNull);
      },
    );
  });
}
