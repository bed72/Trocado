import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class BudgetSaveButtonWidget extends StatelessWidget {
  const BudgetSaveButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: .infinity,
      padding: const .only(top: 16.0),
      child: ButtonWidget.outlined(
        label: 'Salvar',
        isLoading: false,
        onTap: () {
          hideKeyboard();
        },
      ),
    );
  }

  // TODO implementar
  // void _showToast(BuildContext context, ExpenseFormState state) =>
  //     switch (state.status) {
  //       .failure => showToastWidget(
  //         context: context,
  //         type: .failure,
  //         title: state.message ?? 'Erro ao salvar despesa.',
  //       ),
  //       .success => showToastWidget(
  //         context: context,
  //         onClose: context.pop,
  //         title: state.message ?? 'Despesa salva com sucesso.',
  //       ),
  //       _ => {},
  //     };
}
