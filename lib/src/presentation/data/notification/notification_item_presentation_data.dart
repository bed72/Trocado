import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/notification/notification_model.dart';

final class NotificationItemPresentationData extends Equatable {
  final String formattedTime;
  final NotificationModel notification;

  const NotificationItemPresentationData({
    required this.notification,
    required this.formattedTime,
  });

  @override
  List<Object?> get props => [notification, formattedTime];
}
