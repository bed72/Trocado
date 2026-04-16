import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/budget/notifiers/budget_intent.dart';
import 'package:trocado/src/presentation/screens/budget/notifiers/budget_notifier.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class BudgetDateWidget extends StatelessWidget {
  const BudgetDateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        final notifier = ref.read(budgetProvider.notifier);
        PickerDateRange? selectedRange;

        return BottomSheetScaffoldWidget(
          title: 'Período',
          withoutPadding: true,
          subtitle: 'Selecione o período do orçamento.',
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
                  selectionMode: .range,
                  initialDisplayDate: .now(),
                  backgroundColor: context.colors.surface,
                  onSelectionChanged: (args) {
                    if (args.value is PickerDateRange) {
                      selectedRange = args.value;
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
                    final startDate = selectedRange?.startDate;
                    final endDate =
                        selectedRange?.endDate ?? selectedRange?.startDate;

                    if (startDate != null && endDate != null) {
                      notifier.dispatch(
                        DateRangeChanged(
                          startDate: startDate.millisecondsSinceEpoch,
                          endDate: endDate.millisecondsSinceEpoch,
                        ),
                      );
                    }

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
