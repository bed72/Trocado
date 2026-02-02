import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class DateScreen extends StatefulWidget {
  final TransactionCubit cubit;

  const DateScreen({super.key, required this.cubit});

  @override
  State<DateScreen> createState() => _DateScreenState();
}

class _DateScreenState extends State<DateScreen> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();

    _date = widget.cubit.state.form.date;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) {
        widget.cubit.selectDate(_date);
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
              padding: .symmetric(vertical: 16.0, horizontal: 8.0),
              child: BlocConsumer<TransactionCubit, TransactionState>(
                bloc: widget.cubit,
                listenWhen: (previous, current) =>
                    previous.form.date != current.form.date,
                listener: (_, state) {
                  setState(() => _date = state.form.date);
                },
                builder: (_, state) => SfDateRangePicker(
                  view: .month,
                  showNavigationArrow: true,
                  initialDisplayDate: state.form.date,
                  initialSelectedDate: state.form.date,
                  backgroundColor: context.colors.surface,
                  onSelectionChanged: (date) {
                    setState(() => _date = date.value as DateTime);
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
            ),

            Container(
              width: .infinity,
              padding: .only(left: 16.0, right: 16.0, bottom: 20.0),
              child: ButtonWidget.outlined(
                label: 'Selecionar',
                onTap: () {
                  widget.cubit.selectDate(_date);
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
