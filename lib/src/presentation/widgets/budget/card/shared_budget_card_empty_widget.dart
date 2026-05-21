import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SharedBudgetCardEmptyWidget extends StatelessWidget {
  const SharedBudgetCardEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) => Card(
    margin: .zero,
    elevation: 0.0,
    child: Container(
      width: .infinity,
      padding: const .all(16.0),
      child: Column(
        spacing: 8.0,
        mainAxisSize: .min,
        crossAxisAlignment: .center,
        children: [
          const SizedBox(height: 6.0),
          Icon(
            Icons.savings_outlined,
            size: 48.0,
            color: context.colors.outline,
          ),
          Text(
            'Nenhum orçamento de casal ativo',
            textAlign: .center,
            style: context.typography.titleMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6.0),
        ],
      ),
    ),
  );
}
