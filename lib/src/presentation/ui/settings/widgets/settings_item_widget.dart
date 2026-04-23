import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/settings/widgets/settings_premium_badge_widget.dart';

class SettingsItemWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPremium;
  final VoidCallback onTap;

  const SettingsItemWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: onTap,
      child: SizedBox(
        height: 56.0,
        child: Row(
          spacing: 16.0,
          children: [
            Icon(icon, size: 24.0, color: context.colors.onSurfaceVariant),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: .ellipsis,
                style: context.typography.bodyMedium,
              ),
            ),
            if (isPremium) PremiumBadgeWidget(),
            Icon(
              Icons.chevron_right,
              size: 24.0,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
