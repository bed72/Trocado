import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/notification/notification_model.dart';
import 'package:trocado/src/domain/models/notification/notifications_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import 'package:trocado/src/presentation/ui/notifications/notifiers/notifications_state.dart';

part 'notifications_notifier.g.dart';

@Riverpod()
final class NotificationsNotifier extends _$NotificationsNotifier {
  late INotificationRepository _repository;

  @override
  Future<NotificationsState> build() async {
    _repository = ref.watch(notificationRepositoryProvider);

    return await _loadFirstPage();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;

    if (current == null) return;
    if (current.isLoadingMore) return;
    if (current.nextCursor == null) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    );

    final data = await _repository.findAll(cursor: current.nextCursor);

    state = AsyncData(
      data.fold<NotificationsState>(
        (Failure failure) =>
            current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
        (NotificationsPageModel page) => current.copyWith(
          isLoadingMore: false,
          clearLoadMoreFailure: true,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          items: [...current.items, ...page.notifications],
        ),
      ),
    );
  }

  Future<NotificationsState> _loadFirstPage() async {
    final data = await _repository.findAll();

    return data.fold(
      (failure) => throw failure,
      (page) => NotificationsState(
        nextCursor: page.nextCursor,
        items: List<NotificationModel>.from(page.notifications),
      ),
    );
  }
}
