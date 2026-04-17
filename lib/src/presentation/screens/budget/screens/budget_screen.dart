import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/budget/notifiers/form/budget_form_intent.dart';
import 'package:trocado/src/presentation/screens/budget/notifiers/form/budget_form_notifier.dart';

import 'package:trocado/src/presentation/screens/budget/widgets/budget_save_button_widget.dart';
import 'package:trocado/src/presentation/screens/budget/widgets/fields/budget_date_field_widget.dart';
import 'package:trocado/src/presentation/screens/budget/widgets/fields/budget_amount_field_widget.dart';
import 'package:trocado/src/presentation/screens/budget/widgets/fields/budget_description_field_widget.dart';

class BudgetScreen extends StatelessWidget {
  final VoidCallback navigateToDate;
  final VoidCallback navigateToCalculator;

  const BudgetScreen({
    super.key,
    required this.navigateToDate,
    required this.navigateToCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        ref.listen(
          budgetFormProvider,
          (previous, next) => switch (next.status) {
            .success when previous?.status != .success => context.root(),
            .failure when previous?.status != .failure => showToastWidget(
              context: context,
              title: 'Opps',
              type: .failure,
              description: next.message,
            ),
            _ => null,
          },
        );

        final state = ref.watch(budgetFormProvider);
        final notifier = ref.read(budgetFormProvider.notifier);

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
                          'Novo orçamento',
                          style: context.typography.headlineMedium?.copyWith(
                            fontWeight: .bold,
                          ),
                        ),

                        Text(
                          'Preencha as informações abaixo para criar um novo orçamento e acompanhar seus gastos.',
                          style: context.typography.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),

                        BudgetAmountFieldWidget(
                          value: state.value,
                          failure: state.valueFailure,
                          navigateTo: navigateToCalculator,
                        ),
                        BudgetDescriptionFieldWidget(
                          failure: state.descriptionFailure,
                          onChanged: (value) =>
                              notifier.dispatch(DescriptionChanged(value)),
                        ),
                        BudgetDateFieldWidget(
                          endDate: state.endDate,
                          startDate: state.startDate,
                          failure: state.dateFailure,
                          navigateTo: navigateToDate,
                        ),
                      ],
                    ),
                  ),
                ),
                BudgetSaveButtonWidget(
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
