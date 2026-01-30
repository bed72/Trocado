import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/widgets/icons/icon_widget.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class HelperWidget extends StatelessWidget {
  final String title;

  const HelperWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.inverseSurface.withValues(alpha: .72);

    return Padding(
      padding: const .only(left: 4.0, top: 4.0),
      child: Row(
        spacing: 4.0,
        children: [
          IconWidget(size: 16.0, color: color, icon: Icons.info),
          Text(
            title,
            style: context.typography.bodySmall?.copyWith(
              color: color,
              fontWeight: .w500,
            ),
          ),
        ],
      ),
    );
  }
}
