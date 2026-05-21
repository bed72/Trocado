import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/models/notification/notification_model.dart';
import 'package:trocado/src/domain/models/notification/notifications_page_model.dart';
import 'package:trocado/src/domain/enums/notification/notification_type_enum.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import 'package:trocado/src/presentation/notifiers/couple_notifier.dart';

import 'package:trocado/src/presentation/ui/notifications/notifiers/notifications_state.dart';
import 'package:trocado/src/presentation/ui/notifications/data/notification_groups_builder.dart';

import 'package:trocado/src/presentation/data/notification/notification_item_presentation_data.dart';

part 'notifications_notifier.g.dart';

@Riverpod()
final class NotificationsNotifier extends _$NotificationsNotifier {
  late bool _isInCouple;
  late INotificationRepository _repository;
  late IDateFormatterService _dateFormatter;

  @override
  Future<NotificationsState> build() async {
    _repository = ref.watch(notificationRepositoryProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    final couple = await ref.watch(coupleProvider.future);
    _isInCouple = couple != null;

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
        (NotificationsPageModel page) {
          final items = [...current.items, ...page.notifications.map(_toItem)];
          return current.copyWith(
            items: items,
            isLoadingMore: false,
            clearLoadMoreFailure: true,
            nextCursor: page.nextCursor,
            clearNextCursor: page.nextCursor == null,
            groups: buildNotificationGroups(
              items,
              dateFormatter: _dateFormatter,
            ),
          );
        },
      ),
    );
  }

  Future<void> deleteById(int id) async {
    final current = state.value;
    if (current == null) return;

    final originalIndex = current.items.indexWhere(
      (item) => item.notification.id == id,
    );
    if (originalIndex < 0) return;

    final originalItem = current.items[originalIndex];
    final newItems = [...current.items]..removeAt(originalIndex);

    state = AsyncData(
      current.copyWith(
        items: newItems,
        clearDeleteFailure: true,
        groups: buildNotificationGroups(newItems, dateFormatter: _dateFormatter),
      ),
    );

    final data = await _repository.deleteById(id: id);

    data.fold((Failure failure) {
      final restored = [...state.value!.items];
      final insertAt = originalIndex.clamp(0, restored.length);
      restored.insert(insertAt, originalItem);

      state = AsyncData(
        state.value!.copyWith(
          items: restored,
          deleteFailure: failure,
          groups: buildNotificationGroups(
            restored,
            dateFormatter: _dateFormatter,
          ),
        ),
      );
    }, (_) {});
  }

  Future<void> deleteAll() async {
    final current = state.value;
    if (current == null) return;
    if (current.isDeletingAll) return;

    state = AsyncData(
      current.copyWith(isDeletingAll: true, clearDeleteAllFailure: true),
    );

    final data = await _repository.deleteAll();

    state = AsyncData(
      data.fold<NotificationsState>(
        (Failure failure) => state.value!.copyWith(
          isDeletingAll: false,
          deleteAllFailure: failure,
        ),
        (_) => state.value!.copyWith(
          items: const [],
          groups: const [],
          isDeletingAll: false,
          clearNextCursor: true,
          clearDeleteAllFailure: true,
        ),
      ),
    );
  }

  Future<NotificationsState> _loadFirstPage() async {
    final data = await _repository.findAll();

    return data.fold((failure) => throw failure, (page) {
      final items = page.notifications.map(_toItem).toList();

      return NotificationsState(
        items: items,
        nextCursor: page.nextCursor,
        groups: buildNotificationGroups(items, dateFormatter: _dateFormatter),
      );
    });
  }

  NotificationItemPresentationData _toItem(NotificationModel notification) =>
      NotificationItemPresentationData(
        notification: notification,
        formattedTime: _dateFormatter.formatTime(notification.createdAt),
        showLabel: _shouldShowLabel(notification.type),
      );

  bool _shouldShowLabel(NotificationTypeEnum type) => switch (type) {
    .sharedExpenseCreated => _isInCouple,
    .budgetEightyPercent || .unknown => true,
  };
}
