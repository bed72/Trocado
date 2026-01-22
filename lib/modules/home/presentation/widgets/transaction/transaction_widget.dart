import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/transaction.dart';

class TransactionWidget extends StatelessWidget {
  final TransactionDto dto;

  const TransactionWidget({super.key, required this.dto});

  @override
  Widget build(BuildContext context) {
    final isIncome = dto.type == .income;

    final prefix = isIncome ? '+' : '-';
    final color = isIncome ? context.colors.primary : context.colors.error;

    return Card(
      elevation: 0.0,
      margin: .symmetric(horizontal: 0.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: .circular(16.0)),
      child: ListTile(
        contentPadding: const .symmetric(vertical: 8.0, horizontal: 12.0),
        leading: BackgroundIconWidget(
          name: dto.category.icon,
          color: dto.category.color,
        ),
        title: Text(
          dto.description,
          style: context.typography.bodyLarge?.copyWith(fontWeight: .w600),
        ),
        subtitle: Text(
          dto.category.label,
          style: context.typography.labelSmall?.copyWith(
            fontWeight: .w600,
            letterSpacing: 0.5,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        trailing: Text(
          '$prefix ${dto.amount}',
          style: context.typography.bodyLarge?.copyWith(
            color: color,
            fontWeight: .bold,
          ),
        ),
      ),
    );
  }
}
