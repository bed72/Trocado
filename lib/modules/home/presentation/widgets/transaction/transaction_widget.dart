import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/presentation/states/transaction_state.dart';

class TransactionWidget extends StatelessWidget {
  final TransactionState state;

  const TransactionWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isIncome = state.type == .income;

    final prefix = isIncome ? '+' : '-';
    final color = isIncome ? context.colors.primary : context.colors.error;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      child: ListTile(
        contentPadding: const .symmetric(vertical: 8.0, horizontal: 12.0),
        leading: BackgroundIconWidget(
          name: state.category.icon,
          color: state.category.color,
        ),
        title: Text(
          state.label,
          style: context.typography.bodyLarge?.copyWith(fontWeight: .w600),
        ),
        subtitle: Text(
          state.category.label,
          style: context.typography.labelSmall?.copyWith(
            fontWeight: .w600,
            letterSpacing: 0.5,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        trailing: Text(
          '$prefix ${state.amount}',
          style: context.typography.bodyLarge?.copyWith(
            fontWeight: .bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
