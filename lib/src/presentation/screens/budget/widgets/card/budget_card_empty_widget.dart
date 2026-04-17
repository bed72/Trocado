import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class BudgetCardEmptyWidget extends StatelessWidget {
  final VoidCallback onCreateBudget;

  const BudgetCardEmptyWidget({super.key, required this.onCreateBudget});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.0,
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          spacing: 8.0,
          mainAxisSize: .min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48.0,
              color: context.colors.outline,
            ),
            Text(
              'Nenhum orçamento ativo',
              style: context.typography.titleMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            FilledButton(
              onPressed: onCreateBudget,
              child: const Text('Criar orçamento'),
            ),
          ],
        ),
      ),
    );
  }
}
