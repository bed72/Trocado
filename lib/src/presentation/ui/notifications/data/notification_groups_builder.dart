import 'package:trocado/src/domain/services/interface_date_formatter_service.dart';

import 'package:trocado/src/presentation/data/notification/notification_item_presentation_data.dart';

import 'package:trocado/src/presentation/ui/notifications/data/notification_group_presentation_data.dart';

List<NotificationGroupPresentationData> buildNotificationGroups(
  List<NotificationItemPresentationData> items, {
  required IDateFormatterService dateFormatter,
}) {
  if (items.isEmpty) return const [];

  final groups = <NotificationGroupPresentationData>[];
  String? current;
  List<NotificationItemPresentationData> currentBucket = [];

  for (final item in items) {
    final header = dateFormatter.relativeGroupHeader(
      item.notification.createdAt,
    );

    if (current == null || current != header) {
      if (current != null) {
        groups.add(
          NotificationGroupPresentationData(
            header: current,
            notifications: currentBucket,
          ),
        );
      }
      current = header;
      currentBucket = [item];
    } else {
      currentBucket.add(item);
    }
  }

  if (current != null) {
    groups.add(
      NotificationGroupPresentationData(
        header: current,
        notifications: currentBucket,
      ),
    );
  }

  return groups;
}
