import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/ui/budgets/data/budget_item_presentation_data.dart';

class BudgetListItemWidget extends StatelessWidget {
  final BudgetItemPresentationData item;

  const BudgetListItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final overspent = (item.budget.remaining ?? 0) < 0;
    final remainingColor = overspent
        ? context.colors.error
        : context.colors.onSurface;

    return Card(
      elevation: 0.0,
      margin: const .symmetric(horizontal: 16.0, vertical: 6.0),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          spacing: 8.0,
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Row(
              crossAxisAlignment: .center,
              children: [
                Expanded(
                  child: Text(
                    item.budget.description,
                    overflow: .ellipsis,
                    style: context.typography.titleMedium?.copyWith(
                      fontWeight: .w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  item.formattedPeriod,
                  style: context.typography.labelSmall?.copyWith(
                    color: context.colors.outline,
                  ),
                ),
              ],
            ),
            _row(context, 'Valor', item.formattedValue),
            _row(context, 'Gasto', item.formattedTotalSpent),
            _row(
              context,
              'Saldo',
              item.formattedRemaining,
              valueColor: remainingColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) => Row(
    crossAxisAlignment: .end,
    children: [
      Text(
        label,
        style: context.typography.labelSmall?.copyWith(
          color: context.colors.outline,
        ),
      ),
      const SizedBox(width: 6.0),
      Expanded(
        child: Text(
          '.' * 200,
          maxLines: 1,
          softWrap: false,
          overflow: .clip,
          style: context.typography.labelSmall?.copyWith(
            letterSpacing: 2.0,
            color: context.colors.outline,
          ),
        ),
      ),
      const SizedBox(width: 6.0),
      Text(
        value,
        style: context.typography.bodySmall?.copyWith(
          fontWeight: .w600,
          color: valueColor ?? context.colors.onSurface,
        ),
      ),
    ],
  );
}
