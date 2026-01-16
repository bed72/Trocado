import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/presentation/cubits/date_cubit.dart';

class DateScreen extends StatefulWidget {
  final DateCubit cubit;

  const DateScreen({super.key, required this.cubit});

  @override
  State<DateScreen> createState() => _DateScreenState();
}

class _DateScreenState extends State<DateScreen> {
  @override
  void initState() {
    super.initState();

    widget.cubit.reset();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffoldWidget(
      withoutPadding: true,
      title: 'Quando foi?',
      subtitle: 'Selecione o dia em que essa movimentação foi registrada.',
      child: Column(
        mainAxisSize: .min,
        children: [
          Container(
            width: .infinity,
            height: context.height * 0.5,
            padding: .symmetric(vertical: 16.0, horizontal: 8.0),
            child: BlocBuilder<DateCubit, DateState>(
              bloc: widget.cubit,
              builder: (_, state) => SfDateRangePicker(
                view: .month,
                showNavigationArrow: true,
                initialDisplayDate: state.date,
                backgroundColor: context.colors.surface,
                onSelectionChanged: (date) {
                  widget.cubit.select(date.value as DateTime);
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
            padding: .all(16.0),
            child: ButtonWidget.elevated(
              label: 'Selecionar',
              onTap: context.pop,
            ),
          ),
        ],
      ),
    );
  }
}
