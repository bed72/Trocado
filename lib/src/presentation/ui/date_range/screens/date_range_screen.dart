import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/data/date_range_navigation.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class DateRangeScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final int? initialEndDate;
  final int? initialStartDate;
  final DateRangeSelected onSelected;

  const DateRangeScreen({
    super.key,
    this.initialEndDate,
    this.initialStartDate,
    this.title = 'Período',
    required this.onSelected,
    this.subtitle = 'Selecione o período.',
  });

  @override
  State<DateRangeScreen> createState() => _DateRangeScreenState();
}

class _DateRangeScreenState extends State<DateRangeScreen> {
  PickerDateRange? _range;

  @override
  void initState() {
    super.initState();
    if (widget.initialStartDate != null && widget.initialEndDate != null) {
      _range = PickerDateRange(
        .fromMillisecondsSinceEpoch(widget.initialStartDate!),
        .fromMillisecondsSinceEpoch(widget.initialEndDate!),
      );
    }
  }

  @override
  Widget build(BuildContext context) => BottomSheetScaffoldWidget(
    title: widget.title,
    withoutPadding: true,
    subtitle: widget.subtitle,
    child: Column(
      mainAxisSize: .min,
      children: [
        Container(
          width: .infinity,
          height: context.height * 0.5,
          padding: const .symmetric(vertical: 16.0, horizontal: 8.0),
          child: SfDateRangePicker(
            view: .month,
            selectionRadius: 20.0,
            selectionMode: .range,
            showNavigationArrow: true,
            initialDisplayDate: .now(),
            selectionShape: .rectangle,
            initialSelectedRange: _range,
            backgroundColor: context.colors.surface,
            onSelectionChanged: (args) {
              if (args.value is PickerDateRange) {
                setState(() => _range = args.value);
              }
            },
            headerStyle: DateRangePickerHeaderStyle(
              backgroundColor: context.colors.surface,
            ),
            monthViewSettings: const DateRangePickerMonthViewSettings(
              firstDayOfWeek: 1,
              showTrailingAndLeadingDates: true,
            ),
          ),
        ),
        Container(
          width: .infinity,
          padding: const .only(left: 16.0, right: 16.0, bottom: 20.0),
          child: ButtonWidget.outlined(
            label: 'Selecionar',
            onTap: () {
              final startDate = _range?.startDate;
              final endDate = _range?.endDate ?? _range?.startDate;

              if (startDate != null && endDate != null) {
                widget.onSelected(
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
              }

              context.pop();
            },
          ),
        ),
      ],
    ),
  );
}
