import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/models/notification/notification_model.dart';

import 'package:trocado/src/presentation/data/notification/notification_item_presentation_data.dart';

import 'package:trocado/src/presentation/ui/notifications/data/notification_groups_builder.dart';

import '../../../../../mocks/mocks.dart';

NotificationItemPresentationData _item({
  required int id,
  required int millis,
}) => NotificationItemPresentationData(
  showLabel: true,
  formattedTime: '00:00',
  notification: NotificationModel(
    id: id,
    createdAt: millis,
    title: 'Notification #$id',
    type: .sharedExpenseCreated,
    description: 'Description #$id',
  ),
);

void main() {
  late IDateFormatterService dateFormatter;

  setUp(() {
    dateFormatter = MockDateFormatterService();
  });

  group('buildNotificationGroups', () {
    test('returns empty list for empty input', () {
      expect(
        buildNotificationGroups(const [], dateFormatter: dateFormatter),
        isEmpty,
      );
    });

    test('groups items sharing the same header', () {
      const todayA = 1714000000000;
      const todayB = 1714050000000;
      when(() => dateFormatter.relativeGroupHeader(todayA)).thenReturn('Hoje');
      when(() => dateFormatter.relativeGroupHeader(todayB)).thenReturn('Hoje');

      final groups = buildNotificationGroups([
        _item(id: 1, millis: todayA),
        _item(id: 2, millis: todayB),
      ], dateFormatter: dateFormatter);

      expect(groups, hasLength(1));
      expect(groups.first.header, 'Hoje');
      expect(groups.first.notifications.map((item) => item.notification.id), [
        1,
        2,
      ]);
    });

    test('starts a new group when header changes', () {
      const todayA = 1714000000000;
      const todayB = 1714050000000;
      const yesterday = 1713900000000;
      when(() => dateFormatter.relativeGroupHeader(todayA)).thenReturn('Hoje');
      when(() => dateFormatter.relativeGroupHeader(todayB)).thenReturn('Hoje');
      when(
        () => dateFormatter.relativeGroupHeader(yesterday),
      ).thenReturn('Ontem');

      final groups = buildNotificationGroups([
        _item(id: 1, millis: todayA),
        _item(id: 2, millis: todayB),
        _item(id: 3, millis: yesterday),
      ], dateFormatter: dateFormatter);

      expect(groups.map((group) => group.header), ['Hoje', 'Ontem']);
      expect(groups.first.notifications.map((item) => item.notification.id), [
        1,
        2,
      ]);
      expect(groups.last.notifications.single.notification.id, 3);
    });
  });
}
