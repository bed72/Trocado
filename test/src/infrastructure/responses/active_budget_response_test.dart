import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/models/active_budget_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/active_budget_response.dart';
import 'package:trocado/src/data/extensions/active_budget_response_extension.dart';

const _json = {
  'id': 35,
  'value': '18000.00',
  'start_date': '2026-04-01',
  'end_date': '2026-04-30',
  'description': 'Orçamento de Abril',
  'total_spent': '120.00',
  'remaining': '17880.00',
  'created_at': '2026-04-16T14:44:16.671601-03:00',
};

void main() {
  group('ActiveBudgetResponse.fromJson', () {
    test('parses all fields correctly', () {
      final response = ActiveBudgetResponse.fromJson(_json);

      expect(response.id, 35);
      expect(response.value, '18000.00');
      expect(response.startDate, '2026-04-01');
      expect(response.endDate, '2026-04-30');
      expect(response.description, 'Orçamento de Abril');
      expect(response.totalSpent, '120.00');
      expect(response.remaining, '17880.00');
    });

    test('ignores created_at field', () {
      expect(() => ActiveBudgetResponse.fromJson(_json), returnsNormally);
    });
  });

  group('ActiveBudgetResponseExtension.toModel', () {
    test('converts totalSpent to cents correctly', () {
      final model = ActiveBudgetResponse.fromJson(_json).toModel();

      expect(model.totalSpent, 12000);
    });

    test('converts remaining to cents correctly', () {
      final model = ActiveBudgetResponse.fromJson(_json).toModel();

      expect(model.remaining, 1788000);
    });

    test('converts value to cents correctly', () {
      final model = ActiveBudgetResponse.fromJson(_json).toModel();

      expect(model.value, 1800000);
    });

    test('converts start_date to milliseconds since epoch', () {
      final model = ActiveBudgetResponse.fromJson(_json).toModel();

      final date = DateTime.fromMillisecondsSinceEpoch(model.startDate);
      expect(date.year, 2026);
      expect(date.month, 4);
      expect(date.day, 1);
    });

    test('converts end_date to milliseconds since epoch', () {
      final model = ActiveBudgetResponse.fromJson(_json).toModel();

      final date = DateTime.fromMillisecondsSinceEpoch(model.endDate);
      expect(date.year, 2026);
      expect(date.month, 4);
      expect(date.day, 30);
    });

    test('returns ActiveBudgetModel instance', () {
      final model = ActiveBudgetResponse.fromJson(_json).toModel();

      expect(model, isA<ActiveBudgetModel>());
      expect(model.id, 35);
      expect(model.description, 'Orçamento de Abril');
    });
  });
}
