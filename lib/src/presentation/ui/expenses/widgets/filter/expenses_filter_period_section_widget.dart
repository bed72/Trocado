import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:trocado/src/domain/enums/expense/expense_period_preset_enum.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/expenses/widgets/filter/expenses_filter_choice_chip_widget.dart';

class ExpensesFilterPeriodSectionWidget extends StatelessWidget {
  final int? endDate;
  final int? startDate;
  final ExpensePeriodPresetEnum? selectedPreset;
  final ValueChanged<ExpensePeriodPresetEnum> onPresetSelected;

  const ExpensesFilterPeriodSectionWidget({
    super.key,
    required this.endDate,
    required this.startDate,
    required this.selectedPreset,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
    spacing: 8.0,
    crossAxisAlignment: .start,
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
      if (startDate != null && endDate != null) _summary(context),
    ],
  );

  Widget _summary(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy', 'pt_BR');
    final start = format.format(.fromMillisecondsSinceEpoch(startDate!));
    final end = format.format(.fromMillisecondsSinceEpoch(endDate!));

    return Text(
      '$start – $end',
      style: context.typography.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}
