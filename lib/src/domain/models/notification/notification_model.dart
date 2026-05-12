import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/enums/notification/notification_type_enum.dart';

final class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String? link;
  final int createdAt;
  final String description;
  final NotificationTypeEnum type;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.description,
    this.link,
  });

  NotificationModel copyWith({
    int? id,
    String? link,
    String? title,
    int? createdAt,
    String? description,
    NotificationTypeEnum? type,
  }) => NotificationModel(
    id: id ?? this.id,
    type: type ?? this.type,
    link: link ?? this.link,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    description: description ?? this.description,
  );

  @override
  List<Object?> get props => [id, type, title, description, link, createdAt];
}
