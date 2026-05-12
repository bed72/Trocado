import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:trocado/src/domain/enums/notification/notification_type_enum.dart';
import 'package:trocado/src/domain/models/notification/notification_model.dart';

import 'package:trocado/src/presentation/ui/notifications/data/notification_groups_builder.dart';

NotificationModel _item({required int id, required DateTime date}) =>
    NotificationModel(
      id: id,
      type: NotificationTypeEnum.sharedExpenseCreated,
      title: 'Notification #$id',
      description: 'Description #$id',
      createdAt: date.millisecondsSinceEpoch,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('buildNotificationGroups', () {
    test('returns empty list for empty input', () {
      expect(buildNotificationGroups(const []), isEmpty);
    });

    test('groups same-day items under a single "Hoje" header', () {
      final now = DateTime(2026, 4, 22, 22, 0);
      final items = [
        _item(id: 1, date: DateTime(2026, 4, 22, 18, 0)),
        _item(id: 2, date: DateTime(2026, 4, 22, 10, 0)),
      ];

      final groups = buildNotificationGroups(items, now: now);

      expect(groups, hasLength(1));
      expect(groups.first.header, 'Hoje');
      expect(groups.first.notifications.map((item) => item.id), [1, 2]);
    });

    test('emits "Hoje" and "Ontem" in input order', () {
      final now = DateTime(2026, 4, 22, 22, 0);
      final items = [
        _item(id: 1, date: DateTime(2026, 4, 22, 18, 0)),
        _item(id: 2, date: DateTime(2026, 4, 22, 10, 0)),
        _item(id: 3, date: DateTime(2026, 4, 21, 20, 0)),
      ];

      final groups = buildNotificationGroups(items, now: now);

      expect(groups.map((group) => group.header), ['Hoje', 'Ontem']);
      expect(groups.first.notifications.map((item) => item.id), [1, 2]);
      expect(groups.last.notifications.map((item) => item.id), [3]);
    });

    test('uses "Weekday, dd mmm" for dates within the week', () {
      final now = DateTime(2026, 4, 18, 10, 0);
      final items = [_item(id: 1, date: DateTime(2026, 4, 15, 12, 0))];

      final groups = buildNotificationGroups(items, now: now);

      expect(groups, hasLength(1));
      expect(groups.first.header, 'Quarta-feira, 15 abr.');
    });

    test('uses "MMMM yyyy" header for older months', () {
      final now = DateTime(2026, 4, 20, 10, 0);
      final items = [_item(id: 1, date: DateTime(2026, 3, 15, 12, 0))];

      final groups = buildNotificationGroups(items, now: now);

      expect(groups, hasLength(1));
      expect(groups.first.header, 'Março 2026');
    });
  });
}
