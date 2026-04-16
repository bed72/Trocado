import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/budget_response.dart';

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
  });
}
