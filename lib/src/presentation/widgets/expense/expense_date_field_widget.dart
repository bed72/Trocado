import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/extensions/date_time_extension.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

class ExpenseDateFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const ExpenseDateFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: navigateTo,
      child: BlocSelector<ExpenseFormBloc, ExpenseFormState, DateTime>(
        selector: (state) => state.date,
        builder: (_, date) => TextFieldWidget(
          hint: 'Data',
          readOnly: true,
          absorbing: true,
          key: ValueKey(date),
          initialValue: date.format(),
        ),
      ),
    );
  }
}
