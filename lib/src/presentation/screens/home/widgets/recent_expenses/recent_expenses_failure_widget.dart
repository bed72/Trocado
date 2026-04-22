import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class RecentExpensesFailureWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const RecentExpensesFailureWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: 16.0),
      child: Container(
        padding: const .all(12.0),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: context.radius.cornerRadius100,
        ),
        child: Row(
          spacing: 12.0,
          crossAxisAlignment: .center,
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              alignment: .center,
              decoration: BoxDecoration(
                shape: .circle,
                color: context.colors.error.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.error_outline,
                size: 20.0,
                color: context.colors.error,
              ),
            ),
            Expanded(
              child: Column(
                spacing: 8.0,
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Não foi possível carregar as despesas.',
                    maxLines: 2,
                    overflow: .ellipsis,
                    style: context.typography.labelMedium?.copyWith(
                      fontWeight: .w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  ButtonWidget.text(
                    onTap: onRetry,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
