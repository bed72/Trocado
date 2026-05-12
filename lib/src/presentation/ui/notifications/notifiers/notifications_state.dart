import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/notification/notification_model.dart';

final class NotificationsState extends Equatable {
  final String? nextCursor;
  final bool isLoadingMore;
  final Failure? loadMoreFailure;
  final List<NotificationModel> items;

  const NotificationsState({
    this.nextCursor,
    this.loadMoreFailure,
    this.items = const [],
    this.isLoadingMore = false,
  });

  NotificationsState copyWith({
    String? nextCursor,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearNextCursor = false,
    List<NotificationModel>? items,
    bool clearLoadMoreFailure = false,
  }) => NotificationsState(
    items: items ?? this.items,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
  );

  @override
  List<Object?> get props => [
    items,
    nextCursor,
    isLoadingMore,
    loadMoreFailure,
  ];
}
