import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/helper_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

class ExpenseAmountFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const ExpenseAmountFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ExpenseFormBloc,
      ExpenseFormState,
      ({String formatted, String? failure})
    >(
      selector: (state) =>
          (formatted: state.formattedAmount, failure: state.amountFailure),
      builder: (_, data) => BounceWidget.withOnPress(
        onPress: navigateTo,
        child: TextFieldWidget(
          hint: 'Valor',
          readOnly: true,
          absorbing: true,
          placeholder: 'Ex: R\$ 72.00',
          initialValue: data.formatted,
          key: ValueKey(data.formatted),
          helperWidget: data.failure == null
              ? null
              : HelperWidget(title: data.failure!),
        ),
      ),
    );
  }
}
