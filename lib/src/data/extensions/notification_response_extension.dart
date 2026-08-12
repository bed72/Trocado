import 'package:trocado/src/domain/models/page_model.dart';
import 'package:trocado/src/domain/models/notification/notification_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/notification/notification_response.dart';

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

extension NotificationsResponseExtension
    on DataModel<List<NotificationResponse>> {
  PageModel<NotificationModel> toPageModel() => PageModel<NotificationModel>(
    nextCursor: _cursorFrom(links?['next'], 'next_cursor'),
    previousCursor: _cursorFrom(
      links?['previous'] ?? links?['prev'],
      'previous_cursor',
    ),
    items: data.map((item) => item.toModel()).toList(),
  );

  String? _cursorFrom(Object? link, String metaKey) {
    final String? url = link as String?;
    final String? cursor = url == null
        ? null
        : Uri.parse(url).queryParameters['cursor'];
    if (cursor != null) return cursor;

    final pagination = meta?['pagination'];
    if (pagination is! Map) return null;

    return pagination[metaKey] as String?;
  }
}
