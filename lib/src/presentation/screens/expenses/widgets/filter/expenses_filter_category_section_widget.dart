import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/expense/expense_category.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_category_visual_extension.dart';

class ExpensesFilterCategorySectionWidget extends StatelessWidget {
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onSelected;

  const ExpensesFilterCategorySectionWidget({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const List<ExpenseCategory> _categories = [
    .food,
    .debt,
    .health,
    .housing,
    .shopping,
    .transport,
    .entertainment,
  ];

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12.0,
    crossAxisAlignment: .start,
    children: [
      Text(
        'Categoria',
        style: context.typography.titleMedium?.copyWith(fontWeight: .w600),
      ),
      Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _categories
            .map((category) => _chip(context, category))
            .toList(),
      ),
    ],
  );

  Widget _chip(BuildContext context, ExpenseCategory category) {
    final color = category.color(context);
    final isSelected = category == selected;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(category.label),
      avatar: Icon(
        category.icon,
        size: 18.0,
        color: isSelected ? color : context.colors.onSurfaceVariant,
      ),
      selectedColor: color.withValues(alpha: 0.15),
      backgroundColor: context.colors.surfaceContainerHighest,
      onSelected: (_) => onSelected(isSelected ? null : category),
      side: BorderSide(color: isSelected ? color : Colors.transparent),
    );
  }
}
