import 'package:flutter/material.dart';

import 'package:flutter_rearch/flutter_rearch.dart';

import 'package:trocado/src/presentation/capsules/expense_capsule.dart';
import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class ExpenseSaveButtonWidget extends StatelessWidget {
  const ExpenseSaveButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RearchBuilder(
      builder: (_, use) {
        final (form, _) = use(formExpenseCapsule);
        final (save, setSave, _) = use(saveExpenseCapsule);

        return Container(
          width: .infinity,
          padding: const .only(top: 16),
          child: ButtonWidget.outlined(
            label: 'Salvar',
            isLoading: false,
            onTap: form.isValid
                ? () {
                    hideKeyboard;
                    setSave();
                  }
                : null,
          ),
        );
      },
    );
  }
}
