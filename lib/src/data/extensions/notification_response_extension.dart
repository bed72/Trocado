import 'package:trocado/src/domain/models/notification/notification_model.dart';
import 'package:trocado/src/domain/models/notification/notifications_page_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/notification/notification_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/notification/notifications_response.dart';

extension NotificationResponseExtension on NotificationResponse {
  NotificationModel toModel() => NotificationModel(
    id: id,
    link: link,
    title: title,
    type: .fromString(type),
    description: description,
    createdAt: DateTime.parse(createdAt).millisecondsSinceEpoch,
  );
}

extension NotificationsResponseExtension on NotificationsResponse {
  NotificationsPageModel toPageModel() => NotificationsPageModel(
    nextCursor: _cursorFrom(next),
    previousCursor: _cursorFrom(previous),
    notifications: notifications.map((item) => item.toModel()).toList(),
  );

  String? _cursorFrom(String? url) {
    if (url == null) return null;

    return Uri.parse(url).queryParameters['cursor'];
  }
}
