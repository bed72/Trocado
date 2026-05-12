import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/notification/notification_model.dart';

final class NotificationGroupPresentationData extends Equatable {
  final String header;
  final List<NotificationModel> notifications;

  const NotificationGroupPresentationData({
    required this.header,
    required this.notifications,
  });

  @override
  List<Object?> get props => [header, notifications];
}
