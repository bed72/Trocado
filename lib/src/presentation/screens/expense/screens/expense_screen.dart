import 'package:flutter/material.dart' hide ValueChanged;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

import 'package:trocado/src/presentation/screens/expense/notifiers/expense_state.dart';
import 'package:trocado/src/presentation/screens/expense/notifiers/expense_intent.dart';
import 'package:trocado/src/presentation/screens/expense/notifiers/expense_notifier.dart';

import 'package:trocado/src/presentation/screens/expense/widgets/expense_date_field_widget.dart';
import 'package:trocado/src/presentation/screens/expense/widgets/expense_save_button_widget.dart';
import 'package:trocado/src/presentation/screens/expense/widgets/expense_amount_field_widget.dart';
import 'package:trocado/src/presentation/screens/expense/widgets/expense_description_field_widget.dart';

class ExpenseScreen extends StatelessWidget {
  final VoidCallback navigateToDate;
  final void Function(void Function(int)) navigateToCalculator;

  const ExpenseScreen({
    super.key,
    required this.navigateToDate,
    required this.navigateToCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        ref.listen(
          expenseProvider,
          (previous, next) => switch (next.status) {
            ExpenseStatus.success
                when previous?.status != ExpenseStatus.success =>
              context.pop(),
            ExpenseStatus.failure
                when previous?.status != ExpenseStatus.failure =>
              showToastWidget(
                context: context,
                title: 'Opps',
                type: ToastConstant.failure,
                description: next.message,
              ),
            _ => null,
          },
        );

        final state = ref.watch(expenseProvider);
        final notifier = ref.read(expenseProvider.notifier);

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
                          'Nova despesa',
                          style: context.typography.headlineMedium?.copyWith(
                            fontWeight: .bold,
                          ),
                        ),
                        Text(
                          'Preencha as informações abaixo para registrar sua despesa.',
                          style: context.typography.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        ExpenseDescriptionFieldWidget(
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
                ExpenseSaveButtonWidget(
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
