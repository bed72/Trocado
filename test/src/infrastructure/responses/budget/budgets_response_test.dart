import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/budget/budgets_response.dart';

void main() {
  group('BudgetsResponse.fromJson', () {
    test('maps next, previous and results when all present', () {
      const json = {
        'next': 'http://api.example.org/budgets/?cursor=cD00ODY%3D',
        'previous': 'http://api.example.org/budgets/?cursor=cj0xJnA9NDg3',
        'results': [
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
      };

      final response = BudgetsResponse.fromJson(json);

      expect(
        response.next,
        'http://api.example.org/budgets/?cursor=cD00ODY%3D',
      );
      expect(
        response.previous,
        'http://api.example.org/budgets/?cursor=cj0xJnA9NDg3',
      );
      expect(response.budgets.first.id, 9);
      expect(response.budgets, hasLength(1));
      expect(response.budgets.first.remaining, '714.50');
      expect(response.budgets.first.totalSpent, '285.50');
      expect(
        response.budgets.first.createdAt,
        '2026-05-02T17:58:42.119430-03:00',
      );
    });

    test('maps next and previous to null when JSON has null values', () {
      const json = {'next': null, 'previous': null, 'results': []};

      final response = BudgetsResponse.fromJson(json);

      expect(response.next, isNull);
      expect(response.previous, isNull);
    });

    test('returns empty budgets when results is empty', () {
      const json = {'next': null, 'previous': null, 'results': []};

      final response = BudgetsResponse.fromJson(json);

      expect(response.budgets, isEmpty);
    });

    test('parses every entry in results', () {
      const json = {
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 1,
            'value': '100.00',
            'description': 'A',
            'remaining': '90.00',
            'total_spent': '10.00',
            'end_date': '2026-01-31',
            'start_date': '2026-01-01',
            'created_at': '2026-01-02T10:00:00Z',
          },
          {
            'id': 2,
            'value': '200.00',
            'description': 'B',
            'remaining': '180.00',
            'total_spent': '20.00',
            'end_date': '2026-02-28',
            'start_date': '2026-02-01',
            'created_at': '2026-02-02T10:00:00Z',
          },
          {
            'id': 3,
            'value': '300.00',
            'description': 'C',
            'remaining': '270.00',
            'total_spent': '30.00',
            'end_date': '2026-03-31',
            'start_date': '2026-03-01',
            'created_at': '2026-03-02T10:00:00Z',
          },
        ],
      };

      final response = BudgetsResponse.fromJson(json);

      expect(response.budgets, hasLength(3));
      expect(response.budgets.map((b) => b.id).toList(), [1, 2, 3]);
    });
  });
}
