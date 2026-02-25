import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/widgets/helper_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_event.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

class ExpenseDescriptionFieldWidget extends StatelessWidget {
  final ExpenseFormBloc bloc;

  const ExpenseDescriptionFieldWidget({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ExpenseFormBloc,
      ExpenseFormState,
      ({String description, String? failure})
    >(
      selector: (state) =>
          (description: state.description, failure: state.descriptionFailure),
      builder: (_, data) {
        final hasMessage =
            data.failure != null ||
            (data.description.isNotEmpty && data.description.length < 3);

        return TextFieldWidget(
          hint: 'Descrição',
          keyboardType: .name,
          placeholder: 'Ex: Café',
          initialValue: data.description,
          onChanged: (value) => bloc.add(ExpenseDescriptionChanged(value)),
          helperWidget: !hasMessage
              ? null
              : const HelperWidget(
                  title: 'A descrição deve conter ao menos 3 letras.',
                ),
        );
      },
    );
  }
}
