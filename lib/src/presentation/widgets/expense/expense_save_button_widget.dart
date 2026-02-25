import 'package:flutter/material.dart';

import 'package:flutter_rearch/flutter_rearch.dart';

import 'package:trocado/src/presentation/capsules/expense_capsule.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/capsules/states/expense_saved_state.dart';

class ExpenseSaveButtonWidget extends StatelessWidget {
  const ExpenseSaveButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RearchBuilder(
      builder: (_, use) {
        final (form, _) = use(formExpenseCapsule);
        final (state, save) = use(saveExpenseCapsule);

        final isLoading = state is ExpenseSavedLoadingState;

        return Container(
          width: .infinity,
          padding: const .only(top: 16),
          child: ButtonWidget.outlined(
            label: 'Salvar',
            isLoading: isLoading,
            onTap: form.isValid
                ? () {
                    hideKeyboard;

                    final data = save();
                    _showToast(context: context, data: data);
                  }
                : null,
          ),
        );
      },
    );
  }

  void _showToast({
    required BuildContext context,
    required ExpenseSavedState data,
  }) {
    switch (data) {
      case ExpenseSavedFailureState(:final message):
        showToastWidget(context: context, title: message);
      case ExpenseSavedSuccessState(:final message):
        showToastWidget(context: context, title: message, onClose: context.pop);
      case ExpenseSavedLoadingState():
        break;
    }
  }
}
