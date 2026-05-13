import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/presentation/data/notification/notification_item_presentation_data.dart';

import 'package:trocado/src/presentation/ui/notifications/data/notification_group_presentation_data.dart';

final class NotificationsState extends Equatable {
  final String? nextCursor;
  final bool isLoadingMore;
  final bool isDeletingAll;
  final Failure? deleteFailure;
  final Failure? loadMoreFailure;
  final Failure? deleteAllFailure;
  final List<NotificationItemPresentationData> items;
  final List<NotificationGroupPresentationData> groups;

  const NotificationsState({
    this.nextCursor,
    this.deleteFailure,
    this.loadMoreFailure,
    this.deleteAllFailure,
    this.items = const [],
    this.groups = const [],
    this.isLoadingMore = false,
    this.isDeletingAll = false,
  });

  NotificationsState copyWith({
    String? nextCursor,
    bool? isLoadingMore,
    bool? isDeletingAll,
    Failure? deleteFailure,
    Failure? loadMoreFailure,
    Failure? deleteAllFailure,
    bool clearNextCursor = false,
    bool clearDeleteFailure = false,
    bool clearLoadMoreFailure = false,
    bool clearDeleteAllFailure = false,
    List<NotificationItemPresentationData>? items,
    List<NotificationGroupPresentationData>? groups,
  }) => NotificationsState(
    items: items ?? this.items,
    groups: groups ?? this.groups,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isDeletingAll: isDeletingAll ?? this.isDeletingAll,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    deleteFailure: clearDeleteFailure
        ? null
        : deleteFailure ?? this.deleteFailure,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
    deleteAllFailure: clearDeleteAllFailure
        ? null
        : deleteAllFailure ?? this.deleteAllFailure,
  );

  @override
  List<Object?> get props => [
    items,
    groups,
    nextCursor,
    isLoadingMore,
    isDeletingAll,
    deleteFailure,
    loadMoreFailure,
    deleteAllFailure,
  ];
}
