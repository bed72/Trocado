import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/budget/shared_active_budget_response.dart';

const _json = {
  'period': {'start_date': '2026-05-01', 'end_date': '2026-05-31'},
  'me': {
    'value': '2500.00',
    'total_spent': '1556.27',
    'remaining': '943.73',
  },
  'partner': {
    'value': '5000.00',
    'total_spent': '4720.87',
    'remaining': '279.13',
    'name': 'Gabriel Ramos',
    'email': 'gabriel@trocado.app',
  },
  'combined': {
    'value': '7500.00',
    'total_spent': '6277.14',
    'remaining': '1222.86',
  },
  'partner_has_different_period': false,
};

void main() {
  group('SharedActiveBudgetResponse.fromJson', () {
    test('parses all fields correctly', () {
      final response = SharedActiveBudgetResponse.fromJson(_json);

      expect(response.period.startDate, '2026-05-01');
      expect(response.period.endDate, '2026-05-31');
      expect(response.me.value, '2500.00');
      expect(response.me.totalSpent, '1556.27');
      expect(response.me.remaining, '943.73');
      expect(response.partner.name, 'Gabriel Ramos');
      expect(response.partner.email, 'gabriel@trocado.app');
      expect(response.partner.value, '5000.00');
      expect(response.partner.totalSpent, '4720.87');
      expect(response.partner.remaining, '279.13');
      expect(response.combined.value, '7500.00');
      expect(response.combined.totalSpent, '6277.14');
      expect(response.combined.remaining, '1222.86');
      expect(response.partnerHasDifferentPeriod, isFalse);
    });

    test('parses partnerHasDifferentPeriod when true', () {
      final json = Map<String, dynamic>.from(_json);
      json['partner_has_different_period'] = true;

      final response = SharedActiveBudgetResponse.fromJson(json);

      expect(response.partnerHasDifferentPeriod, isTrue);
    });
  });
}
