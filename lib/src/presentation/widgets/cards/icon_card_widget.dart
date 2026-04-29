import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class IconCardWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final IconData? trailing;
  final VoidCallback? onPress;

  const IconCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: .zero,
      elevation: 0.0,
      clipBehavior: .antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: context.radius.cornerRadius100,
      ),
      child: Padding(
        padding: const .all(12.0),
        child: Row(
          spacing: 12.0,
          crossAxisAlignment: .center,
          children: [
            BackgroundIconWidget(
              icon: icon,
              iconSize: 24.0,
              color: context.colors.primary,
            ),
            Expanded(
              child: Column(
                spacing: 2.0,
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    title,
                    style: context.typography.bodyMedium?.copyWith(
                      fontWeight: .bold,
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: .ellipsis,
                    style: context.typography.bodySmall?.copyWith(
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Icon(
                trailing,
                size: 24.0,
                color: context.colors.onSecondaryContainer,
              ),
          ],
        ),
      ),
    );

    if (onPress != null) {
      card = BounceWidget.withOnPress(onPress: onPress, child: card);
    }

    return card;
  }
}
