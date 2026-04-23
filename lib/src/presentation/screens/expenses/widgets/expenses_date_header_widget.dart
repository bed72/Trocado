import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class ExpensesDateHeaderWidget extends StatelessWidget {
  final String label;

  const ExpensesDateHeaderWidget({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(vertical: 12.0, horizontal: 16.0),
    child: Text(
      label,
      style: context.typography.labelMedium?.copyWith(
        fontWeight: .w600,
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}
