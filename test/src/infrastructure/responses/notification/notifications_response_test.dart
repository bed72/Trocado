import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/notification/notifications_response.dart';

void main() {
  group('NotificationsResponse.fromJson', () {
    test('parses cursors and results populated', () {
      final response = NotificationsResponse.fromJson({
        'next': 'http://api.example.org/?cursor=cD00ODY%3D',
        'previous': 'http://api.example.org/?cursor=cj0xJnA9NDg3',
        'results': [
          {
            'id': 42,
            'type': 'shared_expense_created',
            'title': 'Nova despesa do casal',
            'description': 'Gabriel registrou R\$ 85,50 em Mercado.',
            'link': '/expenses/17',
            'created_at': '2026-05-11T14:30:00Z',
          },
          {
            'id': 41,
            'type': 'budget_eighty_percent',
            'title': 'Orçamento em 80%',
            'description': 'Você já gastou R\$ 850,00 de R\$ 1.000,00.',
            'link': '/budgets/active',
            'created_at': '2026-05-11T13:00:00Z',
          },
        ],
      });

      expect(response.next, 'http://api.example.org/?cursor=cD00ODY%3D');
      expect(response.previous, 'http://api.example.org/?cursor=cj0xJnA9NDg3');
      expect(response.notifications, hasLength(2));
      expect(response.notifications.first.id, 42);
      expect(response.notifications.last.id, 41);
    });

    test('accepts null cursors', () {
      final response = NotificationsResponse.fromJson({
        'next': null,
        'previous': null,
        'results': <Map<String, dynamic>>[],
      });

      expect(response.next, isNull);
      expect(response.previous, isNull);
      expect(response.notifications, isEmpty);
    });

    test('accepts empty results list', () {
      final response = NotificationsResponse.fromJson({
        'next': null,
        'previous': null,
        'results': <Map<String, dynamic>>[],
      });

      expect(response.notifications, isEmpty);
    });
  });
}
