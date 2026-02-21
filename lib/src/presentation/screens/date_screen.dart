import 'package:flutter/widgets.dart';

import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class DateScreen extends StatefulWidget {
  const DateScreen({super.key});

  @override
  State<DateScreen> createState() => _DateScreenState();
}

class _DateScreenState extends State<DateScreen> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();

    _date = .now();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) {},
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
                initialDisplayDate: _date,
                initialSelectedDate: _date,
                backgroundColor: context.colors.surface,
                onSelectionChanged: (args) {
                  final value = args.value;
                  if (value is DateTime) {
                    setState(() => _date = value);
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
  }
}
