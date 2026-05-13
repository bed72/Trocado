import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';

import 'package:trocado/src/presentation/ui/notifications/notifiers/notifications_state.dart';
import 'package:trocado/src/presentation/ui/notifications/data/notification_group_presentation_data.dart';

import 'package:trocado/src/presentation/ui/notifications/widgets/notification_card_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_date_header_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notification_dismiss_background_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_load_more_failure_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_load_more_loading_widget.dart';

class NotificationsListWidget extends StatelessWidget {
  final VoidCallback onLoadMore;
  final ValueChanged<int> onDelete;
  final NotificationsState state;
  final List<NotificationGroupPresentationData> groups;

  const NotificationsListWidget({
    super.key,
    required this.state,
    required this.groups,
    required this.onDelete,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      for (final group in groups) ...[
        SliverToBoxAdapter(
          child: NotificationsDateHeaderWidget(label: group.header),
        ),
        SliverList.builder(
          itemCount: group.notifications.length,
          itemBuilder: (_, index) {
            final item = group.notifications[index];

            return Dismissible(
              key: ValueKey(item.notification.id),
              direction: DismissDirection.endToStart,
              background: const NotificationDismissBackgroundWidget(),
              confirmDismiss: (_) => showConfirmDialog(
                context: context,
                confirmLabel: 'Excluir',
                title: 'Excluir notificação',
                description:
                    'Esta ação vai excluir a notificação e não pode ser desfeita.',
              ),
              onDismissed: (_) => onDelete(item.notification.id),
              child: NotificationCardWidget(item: item),
            );
          },
        ),
      ],
      SliverToBoxAdapter(child: _tail()),
    ],
  );

  Widget _tail() {
    if (state.isLoadingMore) {
      return const NotificationsLoadMoreLoadingWidget();
    }
    if (state.loadMoreFailure != null) {
      return NotificationsLoadMoreFailureWidget(onRetry: onLoadMore);
    }

    return const SizedBox.shrink();
  }
}
