import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class ExpenseSaveButtonWidget extends StatelessWidget {
  const ExpenseSaveButtonWidget({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
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
