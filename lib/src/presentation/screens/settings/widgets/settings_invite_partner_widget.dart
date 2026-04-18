import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SettingsInvitePartnerWidget extends StatelessWidget {
  final VoidCallback onTap;

  const SettingsInvitePartnerWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: onTap,
      child: Container(
        padding: const .all(16.0),
        decoration: BoxDecoration(
          borderRadius: .circular(16.0),
          color: context.colors.secondaryContainer,
        ),
        child: Row(
          spacing: 16.0,
          children: [
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                shape: .circle,
                color: context.colors.primaryContainer,
              ),
              child: Icon(
                Icons.person_add_alt,
                size: 20.0,
                color: context.colors.onPrimaryContainer,
              ),
            ),
            Expanded(
              child: Column(
                spacing: 2.0,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Convidar parceiro',
                    style: context.typography.bodyMedium?.copyWith(
                      fontWeight: .bold,
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    'Comecem a usar juntos',
                    style: context.typography.bodySmall?.copyWith(
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 24.0,
              color: context.colors.onSecondaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
