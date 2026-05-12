import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class NotificationsLoadMoreFailureWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const NotificationsLoadMoreFailureWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(vertical: 16.0, horizontal: 16.0),
    child: Column(
      spacing: 8.0,
      mainAxisSize: .min,
      crossAxisAlignment: .center,
      children: [
        Text(
          'Não foi possível carregar mais notificações.',
          textAlign: .center,
          style: context.typography.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        ButtonWidget.text(onTap: onRetry, label: 'Tentar novamente'),
      ],
    ),
  );
}
