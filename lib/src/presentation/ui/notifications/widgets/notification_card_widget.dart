import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';
import 'package:trocado/src/presentation/data/notification/notification_item_presentation_data.dart';
import 'package:trocado/src/presentation/widgets/notification/notification_type_visual_extension.dart';

class NotificationCardWidget extends StatelessWidget {
  final NotificationItemPresentationData item;

  const NotificationCardWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final notification = item.notification;

    return Padding(
      padding: const .symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        spacing: 12.0,
        crossAxisAlignment: .center,
        children: [
          BackgroundIconWidget(
            icon: notification.type.icon,
            color: notification.type.color(context),
          ),
          Expanded(
            child: Column(
              spacing: 4.0,
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Row(
                  spacing: 8.0,
                  crossAxisAlignment: .center,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: .ellipsis,
                        style: context.typography.bodyMedium?.copyWith(
                          fontWeight: .w600,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      item.formattedTime,
                      style: context.typography.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 8.0,
                  crossAxisAlignment: .end,
                  children: [
                    Expanded(
                      child: Text(
                        notification.description,
                        maxLines: 2,
                        overflow: .ellipsis,
                        style: context.typography.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (item.showLabel)
                      Text(
                        notification.type.label,
                        style: context.typography.labelSmall?.copyWith(
                          fontWeight: .w600,
                          color: notification.type.color(context),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
