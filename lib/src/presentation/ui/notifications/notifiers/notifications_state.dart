import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/presentation/data/notification/notification_item_presentation_data.dart';

import 'package:trocado/src/presentation/ui/notifications/data/notification_group_presentation_data.dart';

final class NotificationsState extends Equatable {
  final String? nextCursor;
  final bool isLoadingMore;
  final Failure? loadMoreFailure;
  final List<NotificationItemPresentationData> items;
  final List<NotificationGroupPresentationData> groups;

  const NotificationsState({
    this.nextCursor,
    this.loadMoreFailure,
    this.items = const [],
    this.groups = const [],
    this.isLoadingMore = false,
  });

  NotificationsState copyWith({
    String? nextCursor,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearNextCursor = false,
    bool clearLoadMoreFailure = false,
    List<NotificationItemPresentationData>? items,
    List<NotificationGroupPresentationData>? groups,
  }) => NotificationsState(
    items: items ?? this.items,
    groups: groups ?? this.groups,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
  );

  @override
  List<Object?> get props => [
    items,
    groups,
    nextCursor,
    isLoadingMore,
    loadMoreFailure,
  ];
}
