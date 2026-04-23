import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/expenses/data/expense_filter_chip_kind.dart';
import 'package:trocado/src/presentation/screens/expenses/data/expense_active_filter_chip_data.dart';

class ExpensesActiveFiltersWidget extends StatelessWidget {
  final List<ExpenseActiveFilterChipData> chips;
  final ValueChanged<ExpenseFilterChipKind> onRemove;

  const ExpensesActiveFiltersWidget({
    super.key,
    required this.chips,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40.0,
      child: ListView.separated(
        itemCount: chips.length,
        scrollDirection: .horizontal,
        padding: const .symmetric(horizontal: 16.0),
        separatorBuilder: (_, _) => const SizedBox(width: 8.0),
        itemBuilder: (_, index) => _chip(context, chips[index]),
      ),
    );
  }

  Widget _chip(BuildContext context, ExpenseActiveFilterChipData data) =>
      InputChip(
        label: Text(data.label),
        avatar: data.icon == null
            ? null
            : Icon(
                data.icon,
                size: 18.0,
                color: context.colors.onSurfaceVariant,
              ),
        onDeleted: () => onRemove(data.kind),
        deleteIconColor: context.colors.onSurfaceVariant,
        backgroundColor: context.colors.surfaceContainerHighest,
      );
}
