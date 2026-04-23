import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:trocado/src/domain/models/expense/expense_period_preset.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class ExpensesFilterPeriodSectionWidget extends StatelessWidget {
  final int? endDate;
  final int? startDate;
  final ExpensePeriodPreset? selectedPreset;
  final ValueChanged<ExpensePeriodPreset> onPresetSelected;
  final void Function(int startDate, int endDate) onCustomRangeChanged;

  const ExpensesFilterPeriodSectionWidget({
    super.key,
    required this.endDate,
    required this.startDate,
    required this.selectedPreset,
    required this.onPresetSelected,
    required this.onCustomRangeChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12.0,
    crossAxisAlignment: .start,
    children: [
      Text(
        'Período',
        style: context.typography.titleMedium?.copyWith(fontWeight: .w600),
      ),
      Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: ExpensePeriodPreset.values
            .map((preset) => _chip(context, preset))
            .toList(),
      ),
      if (startDate != null && endDate != null) _summary(context),
      if (selectedPreset == .custom) _picker(context),
    ],
  );

  Widget _chip(BuildContext context, ExpensePeriodPreset preset) {
    final isSelected = preset == selectedPreset;

    return ChoiceChip(
      selected: isSelected,
      label: Text(preset.label),
      onSelected: (_) => onPresetSelected(preset),
      backgroundColor: context.colors.surfaceContainerHighest,
      selectedColor: context.colors.primary.withValues(alpha: 0.15),
      side: BorderSide(
        color: isSelected ? context.colors.primary : Colors.transparent,
      ),
    );
  }

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

  Widget _picker(BuildContext context) => SizedBox(
    height: context.height * 0.45,
    child: SfDateRangePicker(
      view: .month,
      selectionMode: .range,
      showNavigationArrow: true,
      backgroundColor: context.colors.surface,
      initialSelectedRange: (startDate != null && endDate != null)
          ? PickerDateRange(
              .fromMillisecondsSinceEpoch(startDate!),
              .fromMillisecondsSinceEpoch(endDate!),
            )
          : null,
      monthViewSettings: const DateRangePickerMonthViewSettings(
        firstDayOfWeek: 1,
        showTrailingAndLeadingDates: true,
      ),
      onSelectionChanged: (args) {
        if (args.value is! PickerDateRange) return;

        final PickerDateRange(:startDate, :endDate) =
            args.value as PickerDateRange;
        if (startDate == null || endDate == null) return;

        onCustomRangeChanged(
          DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          ).millisecondsSinceEpoch,
          DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
            999,
          ).millisecondsSinceEpoch,
        );
      },
    ),
  );
}
