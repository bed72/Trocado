import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/notification/notification_response.dart';

List<NotificationResponse> _notifications(Object? json) => (json as List)
    .map(
      (item) =>
          NotificationResponse.fromJson(Map<String, dynamic>.from(item as Map)),
    )
    .toList();

void main() {
  test('parses a collection from data and keeps pagination metadata', () {
    final data = DataModel<List<NotificationResponse>>.fromJson({
      'data': [
        {
          'id': 42,
          'type': 'shared_expense_created',
          'title': 'Nova despesa do casal',
          'description': 'Gabriel registrou R\$ 85,50 em Mercado.',
          'link': '/expenses/17',
          'created_at': '2026-05-11T14:30:00Z',
        },
      ],
      'meta': {
        'pagination': {'next_cursor': 'abc'},
      },
      'links': {
        'self': '/v1/notifications',
        'next': '/v1/notifications?cursor=abc',
      },
    }, _notifications);

    expect(data.data, hasLength(1));
    expect(data.data.first.id, 42);
    expect(data.meta?['pagination']['next_cursor'], 'abc');
    expect(data.links?['self'], '/v1/notifications');
    expect(data.links?['next'], '/v1/notifications?cursor=abc');
  });
}
