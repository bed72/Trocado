import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/notification/notification_response.dart';

void main() {
  group('NotificationResponse.fromJson', () {
    test('parses all fields', () {
      final response = NotificationResponse.fromJson({
        'id': 42,
        'type': 'shared_expense_created',
        'title': 'Nova despesa do casal',
        'description': 'Gabriel registrou R\$ 85,50 em Mercado.',
        'link': '/expenses/17',
        'created_at': '2026-05-11T14:30:00Z',
      });

      expect(response.id, 42);
      expect(response.type, 'shared_expense_created');
      expect(response.title, 'Nova despesa do casal');
      expect(response.description, 'Gabriel registrou R\$ 85,50 em Mercado.');
      expect(response.link, '/expenses/17');
      expect(response.createdAt, '2026-05-11T14:30:00Z');
    });

    test('accepts null link', () {
      final response = NotificationResponse.fromJson({
        'id': 1,
        'type': 'unknown_event',
        'title': 'Aviso',
        'description': 'Algo aconteceu.',
        'link': null,
        'created_at': '2026-05-11T14:30:00Z',
      });

      expect(response.link, isNull);
    });
  });
}
