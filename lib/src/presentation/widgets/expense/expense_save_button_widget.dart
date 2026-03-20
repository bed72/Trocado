import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_event.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

class ExpenseSaveButtonWidget extends StatelessWidget {
  final ExpenseFormBloc bloc;

  const ExpenseSaveButtonWidget({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseFormBloc, ExpenseFormState>(
      listener: _showToast,
      listenWhen: (previous, current) => previous.status != current.status,
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isValid != current.isValid,
      builder: (context, state) {
        final isLoading = state.status == .loading;

        return Container(
          width: .infinity,
          padding: const .only(top: 16.0),
          child: ButtonWidget.outlined(
            label: 'Salvar',
            isLoading: isLoading,
            onTap: isLoading
                ? null
                : () {
                    hideKeyboard;
                    bloc.add(const ExpenseFormSubmitted());
                  },
          ),
        );
      },
    );
  }

  void _showToast(BuildContext context, ExpenseFormState state) =>
      switch (state.status) {
        .failure => showToastWidget(
          context: context,
          type: .failure,
          title: state.message ?? 'Erro ao salvar despesa.',
        ),
        .success => showToastWidget(
          context: context,
          onClose: context.pop,
          title: state.message ?? 'Despesa salva com sucesso.',
        ),
        _ => {},
      };
}
