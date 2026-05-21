import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SharedBudgetCardFailureWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const SharedBudgetCardFailureWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0.0,
    child: Container(
      width: .infinity,
      padding: const .all(16.0),
      child: Column(
        spacing: 8.0,
        mainAxisSize: .min,
        children: [
          Icon(Icons.error_outline, size: 48.0, color: context.colors.error),
          Text(
            'Não foi possível carregar o orçamento do casal',
            textAlign: .center,
            style: context.typography.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}
