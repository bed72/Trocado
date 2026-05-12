import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/notification/notification_type_enum.dart';

import 'package:trocado/src/data/extensions/notification_response_extension.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/notification/notification_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/notification/notifications_response.dart';

void main() {
  group('NotificationResponseExtension.toModel', () {
    test('maps every field and parses createdAt to milliseconds', () {
      final response = NotificationResponse(
        id: 42,
        type: 'shared_expense_created',
        title: 'Nova despesa do casal',
        description: 'Gabriel registrou R\$ 85,50 em Mercado.',
        link: '/expenses/17',
        createdAt: '2026-05-11T14:30:00Z',
      );

      final model = response.toModel();

      expect(model.id, 42);
      expect(model.type, NotificationTypeEnum.sharedExpenseCreated);
      expect(model.title, 'Nova despesa do casal');
      expect(model.description, 'Gabriel registrou R\$ 85,50 em Mercado.');
      expect(model.link, '/expenses/17');
      expect(
        model.createdAt,
        DateTime.parse('2026-05-11T14:30:00Z').millisecondsSinceEpoch,
      );
    });

    test('maps unknown type to unknown enum', () {
      final response = NotificationResponse(
        id: 1,
        type: 'some_future_type',
        title: 't',
        description: 'd',
        createdAt: '2026-05-11T14:30:00Z',
      );

      expect(response.toModel().type, NotificationTypeEnum.unknown);
    });

    test('preserves null link', () {
      final response = NotificationResponse(
        id: 1,
        type: 'shared_expense_created',
        title: 't',
        description: 'd',
        createdAt: '2026-05-11T14:30:00Z',
      );

      expect(response.toModel().link, isNull);
    });
  });

  group('NotificationsResponseExtension.toPageModel', () {
    test('extracts cursor query param from next and previous URLs', () {
      final response = NotificationsResponse(
        next: 'http://api.example.org/path?cursor=cD00ODY%3D&page_size=10',
        previous: 'http://api.example.org/path?cursor=cj0xJnA9NDg3',
        notifications: const [],
      );

      final page = response.toPageModel();

      expect(page.nextCursor, 'cD00ODY=');
      expect(page.previousCursor, 'cj0xJnA9NDg3');
    });

    test('null URL maps to null cursor', () {
      final response = const NotificationsResponse(
        next: null,
        previous: null,
        notifications: [],
      );

      final page = response.toPageModel();

      expect(page.nextCursor, isNull);
      expect(page.previousCursor, isNull);
    });

    test('URL without cursor query param maps to null cursor', () {
      final response = const NotificationsResponse(
        next: 'http://api.example.org/path',
        previous: 'http://api.example.org/path?other=1',
        notifications: [],
      );

      final page = response.toPageModel();

      expect(page.nextCursor, isNull);
      expect(page.previousCursor, isNull);
    });

    test('maps each NotificationResponse to a NotificationModel', () {
      final response = NotificationsResponse(
        next: null,
        previous: null,
        notifications: [
          NotificationResponse(
            id: 1,
            type: 'shared_expense_created',
            title: 't1',
            description: 'd1',
            createdAt: '2026-05-11T14:30:00Z',
          ),
          NotificationResponse(
            id: 2,
            type: 'budget_eighty_percent',
            title: 't2',
            description: 'd2',
            createdAt: '2026-05-11T13:00:00Z',
          ),
        ],
      );

      final page = response.toPageModel();

      expect(page.notifications, hasLength(2));
      expect(page.notifications[0].id, 1);
      expect(
        page.notifications[0].type,
        NotificationTypeEnum.sharedExpenseCreated,
      );
      expect(
        page.notifications[1].type,
        NotificationTypeEnum.budgetEightyPercent,
      );
    });
  });
}
