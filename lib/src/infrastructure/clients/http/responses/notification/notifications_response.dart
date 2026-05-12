import 'package:trocado/src/infrastructure/clients/http/responses/notification/notification_response.dart';

final class NotificationsResponse {
  final String? next;
  final String? previous;
  final List<NotificationResponse> notifications;

  const NotificationsResponse({
    required this.notifications,
    this.next,
    this.previous,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) =>
      NotificationsResponse(
        next: json['next'] as String?,
        previous: json['previous'] as String?,
        notifications: (json['results'] as List)
            .map(
              (item) =>
                  NotificationResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}
