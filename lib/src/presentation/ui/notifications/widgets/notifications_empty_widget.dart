import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class NotificationsEmptyWidget extends StatelessWidget {
  const NotificationsEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(24.0),
    child: Column(
      spacing: 12.0,
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      children: [
        BackgroundIconWidget(
          icon: Icons.notifications_none_outlined,
          color: context.colors.primary,
        ),
        Text(
          'Nenhuma notificação ainda',
          textAlign: .center,
          style: context.typography.titleMedium?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurface,
          ),
        ),
        Text(
          'Quando algo importante acontecer, você verá aqui.',
          textAlign: .center,
          style: context.typography.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
