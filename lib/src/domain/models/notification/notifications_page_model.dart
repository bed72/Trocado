import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/notification/notification_model.dart';

final class NotificationsPageModel extends Equatable {
  final String? nextCursor;
  final String? previousCursor;
  final List<NotificationModel> notifications;

  const NotificationsPageModel({
    this.nextCursor,
    this.previousCursor,
    this.notifications = const [],
  });

  NotificationsPageModel copyWith({
    String? nextCursor,
    String? previousCursor,
    List<NotificationModel>? notifications,
  }) => NotificationsPageModel(
    nextCursor: nextCursor ?? this.nextCursor,
    notifications: notifications ?? this.notifications,
    previousCursor: previousCursor ?? this.previousCursor,
  );

  @override
  List<Object?> get props => [notifications, nextCursor, previousCursor];
}
