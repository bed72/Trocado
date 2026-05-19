import 'package:flutter/material.dart';

import 'package:trocado/src/domain/enums/expense/expense_period_preset_enum.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/expenses/widgets/filter/expenses_filter_choice_chip_widget.dart';

class ExpensesFilterPeriodSectionWidget extends StatelessWidget {
  final String? formattedSummary;
  final ExpensePeriodPresetEnum? selectedPreset;
  final ValueChanged<ExpensePeriodPresetEnum> onPresetSelected;

  const ExpensesFilterPeriodSectionWidget({
    super.key,
    required this.selectedPreset,
    required this.formattedSummary,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
    spacing: 8.0,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Período',
        style: context.typography.titleMedium?.copyWith(fontWeight: .w600),
      ),
      Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: ExpensePeriodPresetEnum.values
            .map(
              (preset) => ExpensesFilterChoiceChipWidget(
                label: preset.label,
                isSelected: preset == selectedPreset,
                onTap: () => onPresetSelected(preset),
              ),
            )
            .toList(),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: .topLeft,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: formattedSummary == null
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : Text(
                  'De: ${formattedSummary!}',
                  key: ValueKey(formattedSummary),
                  style: context.typography.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    ],
  );
}
