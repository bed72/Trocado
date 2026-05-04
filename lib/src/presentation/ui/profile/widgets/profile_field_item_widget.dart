import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

class ProfileFieldItemWidget extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const ProfileFieldItemWidget({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final body = SizedBox(
      height: 56.0,
      child: Row(
        spacing: 16.0,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: .ellipsis,
              style: context.typography.bodyMedium?.copyWith(
                color: enabled ? null : context.colors.onSurfaceVariant,
              ),
            ),
          ),
          if (enabled)
            Icon(
              Icons.chevron_right,
              size: 24.0,
              color: context.colors.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (!enabled) return body;

    return BounceWidget.withOnPress(onPress: onTap, child: body);
  }
}
