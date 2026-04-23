import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class SettingsInvitePartnerWidget extends StatelessWidget {
  final VoidCallback onTap;

  const SettingsInvitePartnerWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: onTap,
      child: Card(
        margin: .zero,
        elevation: 0.0,
        shape: RoundedRectangleBorder(borderRadius: .circular(16.0)),
        child: Padding(
          padding: const .all(16.0),
          child: Row(
            spacing: 16.0,
            children: [
              BackgroundIconWidget(
                width: 40.0,
                height: 40.0,
                iconSize: 20.0,
                icon: Icons.person_add_alt,
                color: context.colors.primary,
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
      ),
    );
  }
}
