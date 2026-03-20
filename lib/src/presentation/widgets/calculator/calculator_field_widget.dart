import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

class CalculatorFieldWidget extends StatelessWidget {
  const CalculatorFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExpenseFormBloc, ExpenseFormState, String>(
      selector: (state) => state.formattedAmount,
      builder: (context, value) {
        return TextFieldWidget(
          hint: 'Valor',
          readOnly: true,
          absorbing: true,
          placeholder: '72.0',
          initialValue: value,
          key: ValueKey(value.hashCode),
        );
      },
    );
  }
}
