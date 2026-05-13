import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/ui/notifications/notifiers/notifications_state.dart';
import 'package:trocado/src/presentation/ui/notifications/data/notification_group_presentation_data.dart';

import 'package:trocado/src/presentation/ui/notifications/widgets/notification_card_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_date_header_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_load_more_failure_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_load_more_loading_widget.dart';

class NotificationsListWidget extends StatelessWidget {
  final VoidCallback onLoadMore;
  final NotificationsState state;
  final List<NotificationGroupPresentationData> groups;

  const NotificationsListWidget({
    super.key,
    required this.state,
    required this.groups,
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

            return NotificationCardWidget(
              key: ValueKey(item.notification.id),
              item: item,
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
