import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_active_filter_chip_presentation_data.dart';

class ExpensesActiveFiltersWidget extends StatelessWidget {
  final List<ExpenseActiveFilterChipPresentationData> chips;
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

  Widget _chip(BuildContext context, ExpenseActiveFilterChipPresentationData data) =>
      InputChip(
        elevation: 0.0,
        labelPadding: const .only(left: 4.0, right: 4.0, bottom: 1.0),
        label: Row(
          spacing: 6.0,
          mainAxisSize: .min,
          children: [
            if (data.icon != null)
              Icon(
                data.icon,
                size: 16.0,
                color: context.colors.onSurfaceVariant,
              ),
            Text(data.label),
          ],
        ),
        onDeleted: () => onRemove(data.kind),
        deleteIcon: Container(
          padding: .only(top: 2.0),
          child: Icon(
            Icons.close,
            size: 16.0,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        backgroundColor: context.colors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: context.radius.cornerRadius050,
          side: BorderSide(color: Colors.transparent),
        ),
      );
}
