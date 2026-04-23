import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SettingsSectionWidget extends StatelessWidget {
  final String label;

  const SettingsSectionWidget({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: context.typography.labelSmall?.copyWith(
      fontWeight: .w600,
      letterSpacing: 1.2,
      color: context.colors.onSurfaceVariant,
    ),
  );
}
