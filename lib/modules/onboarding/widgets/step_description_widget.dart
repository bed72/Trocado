import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class StepDescriptionWidget extends StatelessWidget {
  final String value;
  const StepDescriptionWidget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: .center,
      style: context.typography.bodyLarge?.copyWith(
        height: 1.4,
        fontWeight: .w500,
        color: context.colors.inverseSurface.withValues(alpha: 0.72),
      ),
    );
  }
}
