import 'package:equatable/equatable.dart';

import 'package:trocado/src/presentation/data/notification/notification_item_presentation_data.dart';

final class NotificationGroupPresentationData extends Equatable {
  final String header;
  final List<NotificationItemPresentationData> notifications;

  const NotificationGroupPresentationData({
    required this.header,
    required this.notifications,
  });

  @override
  List<Object?> get props => [header, notifications];
}
