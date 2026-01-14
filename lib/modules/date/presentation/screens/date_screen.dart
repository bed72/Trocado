import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:trocado/modules/core/core.dart';

class DateScreen extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> date;

  const DateScreen({super.key, required this.date, this.initialDate});

  @override
  State<DateScreen> createState() => _DateScreenState();
}

class _DateScreenState extends State<DateScreen> {
  late DateTime? _selectDate;

  @override
  void initState() {
    super.initState();

    _selectDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffoldWidget(
      title: 'Quando foi?',
      subtitle: 'Selecione o dia em que essa movimentação foi registrada.',
      child: Column(
        mainAxisSize: .min,
        children: [
          Container(
            width: .infinity,
            height: context.height * 0.5,
            padding: .only(top: 16.0, bottom: 16.0),
            child: SfDateRangePicker(
              view: .month,
              showNavigationArrow: true,
              initialDisplayDate: _selectDate,
              backgroundColor: context.colors.surface,
              onSelectionChanged: (date) {
                setState(() => _selectDate = date.value as DateTime);
              },
              headerStyle: DateRangePickerHeaderStyle(
                backgroundColor: context.colors.surface,
              ),
              monthViewSettings: DateRangePickerMonthViewSettings(
                firstDayOfWeek: 1,
                showTrailingAndLeadingDates: true,
              ),
            ),
          ),

          Container(
            width: .infinity,
            padding: .only(bottom: 20.0),
            child: ButtonWidget.elevated(
              label: 'Selecionar',
              onTap: _selectDate == null
                  ? null
                  : () {
                      widget.date(_selectDate!);

                      context.pop();
                    },
            ),
          ),
        ],
      ),
    );
  }
}
