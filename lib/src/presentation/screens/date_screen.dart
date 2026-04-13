import 'package:flutter/widgets.dart';

import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class DateScreen extends StatelessWidget {
  const DateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffoldWidget(
      title: 'Quando foi?',
      withoutPadding: true,
      subtitle: 'Selecione o dia desta despesa.',
      child: Column(
        mainAxisSize: .min,
        children: [
          Container(
            width: .infinity,
            height: context.height * 0.5,
            padding: const .symmetric(vertical: 16.0, horizontal: 8.0),
            child: SfDateRangePicker(
              view: .month,
              showNavigationArrow: true,
              initialDisplayDate: .now(),
              initialSelectedDate: .now(),
              backgroundColor: context.colors.surface,
              onSelectionChanged: (args) {
                final date = args.value;
                // if (date is DateTime) bloc.add(ExpenseDateChanged(date));
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
              onTap: context.pop,
            ),
          ),
        ],
      ),
    );
  }
}
