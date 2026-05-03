import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class BudgetsEmptyWidget extends StatelessWidget {
  const BudgetsEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(24.0),
    child: Column(
      spacing: 12.0,
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      children: [
        BackgroundIconWidget(
          icon: Icons.savings_outlined,
          color: context.colors.primary,
        ),
        Text(
          'Nenhum orçamento ainda',
          textAlign: .center,
          style: context.typography.titleMedium?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurface,
          ),
        ),
        Text(
          'Quando você criar orçamentos eles aparecerão aqui.',
          textAlign: .center,
          style: context.typography.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
