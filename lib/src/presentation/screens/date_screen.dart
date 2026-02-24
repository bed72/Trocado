import 'package:flutter/widgets.dart';
import 'package:flutter_rearch/flutter_rearch.dart';

import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:trocado/src/presentation/capsules/date_capsule.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class DateScreen extends StatelessWidget {
  const DateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RearchBuilder(
      builder: (_, use) {
        final (value, setValue) = use(dateCapsule);

        return PopScope(
          onPopInvokedWithResult: (_, _) {
            setValue(value);
          },
          child: BottomSheetScaffoldWidget(
            withoutPadding: true,
            title: 'Quando foi?',
            subtitle: 'Selecione o dia desta movimentação.',
            child: Column(
              mainAxisSize: .min,
              children: [
                Container(
                  width: .infinity,
                  height: context.height * 0.5,
                  padding: const .symmetric(vertical: 16, horizontal: 8),
                  child: SfDateRangePicker(
                    view: .month,
                    showNavigationArrow: true,
                    initialDisplayDate: value,
                    initialSelectedDate: value,
                    backgroundColor: context.colors.surface,
                    onSelectionChanged: (args) {
                      final date = args.value;
                      if (date is DateTime) setValue(date);
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
                  padding: const .only(left: 16, right: 16, bottom: 20),
                  child: ButtonWidget.outlined(
                    label: 'Selecionar',
                    onTap: () {
                      context.pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
