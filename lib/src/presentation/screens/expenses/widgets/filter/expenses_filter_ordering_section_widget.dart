import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/expense/expense_ordering.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class ExpensesFilterOrderingSectionWidget extends StatelessWidget {
  final ExpenseOrdering selected;
  final ValueChanged<ExpenseOrdering> onSelected;

  const ExpensesFilterOrderingSectionWidget({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12.0,
    crossAxisAlignment: .start,
    children: [
      Text(
        'Ordenação',
        style: context.typography.titleMedium?.copyWith(fontWeight: .w600),
      ),
      Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: ExpenseOrdering.values
            .map((ordering) => _chip(context, ordering))
            .toList(),
      ),
    ],
  );

  Widget _chip(BuildContext context, ExpenseOrdering ordering) {
    final isSelected = ordering == selected;

    return ChoiceChip(
      selected: isSelected,
      label: Text(ordering.label),
      onSelected: (_) => onSelected(ordering),
      backgroundColor: context.colors.surfaceContainerHighest,
      selectedColor: context.colors.primary.withValues(alpha: 0.15),
      side: BorderSide(
        color: isSelected ? context.colors.primary : Colors.transparent,
      ),
    );
  }
}
