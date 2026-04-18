import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class ScreenHeaderWidget extends StatelessWidget {
  final String title;
  final String description;

  const ScreenHeaderWidget({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      Text(
        title,
        style: context.typography.headlineMedium?.copyWith(
          fontWeight: .bold,
        ),
      ),
      const SizedBox(height: 8.0),
      Text(
        description,
        style: context.typography.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
