import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/calculator/calculator.dart';
import 'package:trocado/modules/transaction/transaction.dart';

class TransactionWidget extends StatelessWidget {
  final TransactionDto dto;
  final ValueChanged<TransactionDto> onPress;

  late final MoneyDto _moneyDto;

  TransactionWidget({super.key, required this.dto, required this.onPress}) {
    _moneyDto = MoneyDto();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = dto.type == .income;

    final prefix = isIncome ? '+' : '-';
    final color = isIncome ? context.colors.primary : context.colors.error;

    return BounceWidget.withTap(
      onTap: () => onPress(dto),
      child: Card(
        margin: .symmetric(horizontal: 0.0, vertical: 4.0),
        child: ListTile(
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
          trailing: dto.amount == null
              ? null
              : Text(
                  '$prefix ${_moneyDto.format(dto.amount!)}',
                  style: context.typography.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: .bold,
                  ),
                ),
        ),
      ),
    );
  }
}
