import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_category_visual_extension.dart';

class ExpenseItemWidget extends StatelessWidget {
  final ExpenseModel expense;
  final String formattedValue;

  const ExpenseItemWidget({
    super.key,
    required this.expense,
    required this.formattedValue,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(expense.createdAt);
    final date = DateFormat('dd/MM', 'pt_BR').format(createdAt);
    final time = DateFormat('HH:mm', 'pt_BR').format(createdAt);

    return Padding(
      padding: const .symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        spacing: 12.0,
        crossAxisAlignment: .center,
        children: [
          BackgroundIconWidget(
            icon: expense.category.icon,
            color: expense.category.color(context),
          ),
          Expanded(
            child: Column(
              spacing: 4.0,
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Text(
                  expense.description,
                  maxLines: 1,
                  softWrap: false,
                  overflow: .ellipsis,
                  style: context.typography.bodyMedium?.copyWith(
                    fontWeight: .w600,
                    color: context.colors.onSurface,
                  ),
                ),
                Text(
                  expense.category.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: .ellipsis,
                  style: context.typography.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            spacing: 4.0,
            mainAxisSize: .min,
            crossAxisAlignment: .end,
            children: [
              Text(
                formattedValue,
                style: context.typography.bodyMedium?.copyWith(
                  fontWeight: .w600,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                '$date · $time',
                style: context.typography.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
