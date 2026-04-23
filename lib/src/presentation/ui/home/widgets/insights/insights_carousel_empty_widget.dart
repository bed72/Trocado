import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class InsightsCarouselEmptyWidget extends StatelessWidget {
  const InsightsCarouselEmptyWidget({super.key});

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
            BackgroundIconWidget(
              iconSize: 20.0,
              icon: Icons.lightbulb_outline,
              color: context.colors.primary,
            ),
            Expanded(
              child: Column(
                spacing: 4.0,
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Ainda sem insights',
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.typography.labelMedium?.copyWith(
                      fontWeight: .w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Text(
                    'Registre mais despesas para liberar sugestões.',
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
