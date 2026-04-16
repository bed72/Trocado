import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/expense/notifiers/expense_intent.dart';
import 'package:trocado/src/presentation/screens/expense/notifiers/expense_notifier.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class ExpenseDateScreen extends StatefulWidget {
  const ExpenseDateScreen({super.key});

  @override
  State<ExpenseDateScreen> createState() => _ExpenseDateScreenState();
}

class _ExpenseDateScreenState extends State<ExpenseDateScreen> {
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        final notifier = ref.read(expenseProvider.notifier);

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
                  view: DateRangePickerView.month,
                  selectionMode: .single,
                  showNavigationArrow: true,
                  initialDisplayDate: .now(),
                  initialSelectedDate: .now(),
                  backgroundColor: context.colors.surface,
                  onSelectionChanged: (args) {
                    if (args.value is DateTime) {
                      setState(() => _date = args.value as DateTime);
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
                width: double.infinity,
                padding: const .only(left: 16.0, right: 16.0, bottom: 20.0),
                child: ButtonWidget.outlined(
                  label: 'Selecionar',
                  onTap: () {
                    notifier.dispatch(
                      DateChanged(_date.millisecondsSinceEpoch),
                    );
                    context.pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
