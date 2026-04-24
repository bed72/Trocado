import 'package:flutter/material.dart' hide ValueChanged;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/expense/notifiers/expense_intent.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/expense_notifier.dart';

import 'package:trocado/src/presentation/ui/expense/widgets/expense_date_field_widget.dart';
import 'package:trocado/src/presentation/ui/expense/widgets/expense_save_button_widget.dart';
import 'package:trocado/src/presentation/ui/expense/widgets/expense_amount_field_widget.dart';
import 'package:trocado/src/presentation/ui/expense/widgets/expense_edit_actions_widget.dart';
import 'package:trocado/src/presentation/ui/expense/widgets/expense_description_field_widget.dart';

class ExpenseScreen extends StatelessWidget {
  // TODO deveriamos passar so o ID
  final ExpenseModel? expense;
  final VoidCallback navigateToDate;
  final void Function(void Function(int)) navigateToCalculator;

  const ExpenseScreen({
    super.key,
    this.expense,
    required this.navigateToDate,
    required this.navigateToCalculator,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing = expense != null;
    final title = isEditing ? 'Editar despesa' : 'Nova despesa';
    final subtitle = isEditing
        ? 'Atualize as informações da sua despesa.'
        : 'Preencha as informações abaixo para registrar sua despesa.';

    return Consumer(
      builder: (_, ref, _) {
        ref.listen(
          expenseProvider(expense),
          (previous, next) => switch (next.status) {
            .success when previous?.status != .success => context.pop(),
            .failure when previous?.status != .failure => showToastWidget(
              context: context,
              title: 'Opps',
              type: .failure,
              description: next.message,
            ),
            _ => null,
          },
        );

        final state = ref.watch(expenseProvider(expense));
        final notifier = ref.read(expenseProvider(expense).notifier);

        return ScaffoldWidget(
          appBar: AppBarWidget(leading: GoBackWidget()),
          child: Padding(
            padding: const .all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      spacing: 16.0,
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          title,
                          style: context.typography.headlineMedium?.copyWith(
                            fontWeight: .bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: context.typography.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        ExpenseDescriptionFieldWidget(
                          initialValue: state.description,
                          failure: state.descriptionFailure,
                          onChanged: (value) =>
                              notifier.dispatch(DescriptionChanged(value)),
                        ),
                        ExpenseAmountFieldWidget(
                          value: state.value,
                          failure: state.valueFailure,
                          navigateTo: () => navigateToCalculator(
                            (value) => notifier.dispatch(ValueChanged(value)),
                          ),
                        ),
                        ExpenseDateFieldWidget(
                          date: state.date,
                          failure: state.dateFailure,
                          navigateTo: navigateToDate,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isEditing)
                  ExpenseEditActionsWidget(
                    isLoading: state.status == .loading,
                    isDeleting: state.isDeleting,
                    onUpdate: () {
                      hideKeyboard();
                      notifier.dispatch(const SubmitPressed());
                    },
                    onDelete: () {
                      hideKeyboard();
                      notifier.dispatch(const DeletePressed());
                    },
                  )
                else
                  ExpenseSaveButtonWidget(
                    label: 'Cadastrar',
                    isLoading: state.status == .loading,
                    onSave: () {
                      hideKeyboard();
                      notifier.dispatch(const SubmitPressed());
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
