import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class RecentExpensesEmptyWidget extends StatelessWidget {
  const RecentExpensesEmptyWidget({super.key});

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
                color: context.colors.primary.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 20.0,
                color: context.colors.primary,
              ),
            ),
            Expanded(
              child: Column(
                spacing: 4.0,
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Ainda sem despesas',
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.typography.labelMedium?.copyWith(
                      fontWeight: .w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Text(
                    'Suas despesas mais recentes aparecerão aqui.',
                    maxLines: 2,
                    overflow: .ellipsis,
                    style: context.typography.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
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
