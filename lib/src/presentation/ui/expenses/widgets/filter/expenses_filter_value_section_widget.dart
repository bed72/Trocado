import 'package:flutter/material.dart';

import 'package:trocado/src/domain/enums/expense/expense_value_preset_enum.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/expenses/widgets/filter/expenses_filter_choice_chip_widget.dart';

class ExpensesFilterValueSectionWidget extends StatelessWidget {
  final ExpenseValuePresetEnum? selectedPreset;
  final ValueChanged<ExpenseValuePresetEnum> onPresetSelected;

  const ExpensesFilterValueSectionWidget({
    super.key,
    required this.selectedPreset,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
    spacing: 8.0,
    crossAxisAlignment: .start,
    children: [
      Text(
        'Valor',
        style: context.typography.titleMedium?.copyWith(fontWeight: .w600),
      ),
      Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: ExpenseValuePresetEnum.values
            .map(
              (preset) => ExpensesFilterChoiceChipWidget(
                label: preset.label,
                isSelected: preset == selectedPreset,
                onTap: () => onPresetSelected(preset),
              ),
            )
            .toList(),
      ),
    ],
  );
}
