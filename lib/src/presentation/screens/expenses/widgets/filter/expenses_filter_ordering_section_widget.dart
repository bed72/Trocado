import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/expense/expense_ordering.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/expenses/widgets/filter/expenses_filter_choice_chip_widget.dart';

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
    spacing: 8.0,
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
            .map(
              (ordering) => ExpensesFilterChoiceChipWidget(
                label: ordering.label,
                isSelected: ordering == selected,
                onTap: () => onSelected(ordering),
              ),
            )
            .toList(),
      ),
    ],
  );
}
