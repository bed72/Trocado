import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/presentation/widgets/icon_widget.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class HelperWidget extends StatelessWidget {
  final String title;

  const HelperWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.inverseSurface.withValues(alpha: .72);

    return Row(
      spacing: 4.0,
      children: [
        IconWidget(size: 16.0, color: color, name: LucideIcons.info300),
        Text(
          title,
          style: context.typography.bodySmall?.copyWith(
            color: color,
            fontWeight: .w500,
          ),
        ),
      ],
    );
  }
}
