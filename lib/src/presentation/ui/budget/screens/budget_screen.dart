import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' hide ValueChanged;

import 'package:trocado/src/presentation/data/date_range_navigation.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';
import 'package:trocado/src/presentation/widgets/circular_progress_indicator_widget.dart';

import 'package:trocado/src/presentation/ui/budget/notifiers/budget_by_id_notifier.dart';
import 'package:trocado/src/presentation/ui/budget/notifiers/form/budget_form_state.dart';
import 'package:trocado/src/presentation/ui/budget/notifiers/form/budget_form_intent.dart';
import 'package:trocado/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart';

import 'package:trocado/src/presentation/ui/budget/widgets/budget_save_button_widget.dart';
import 'package:trocado/src/presentation/ui/budget/widgets/budget_edit_actions_widget.dart';
import 'package:trocado/src/presentation/ui/budget/widgets/fields/budget_date_field_widget.dart';
import 'package:trocado/src/presentation/ui/budget/widgets/fields/budget_amount_field_widget.dart';
import 'package:trocado/src/presentation/ui/budget/widgets/fields/budget_description_field_widget.dart';

class BudgetScreen extends StatelessWidget {
  final int? id;
  final NavigateToDateRange navigateToDate;
  final void Function(void Function(int centValue)) navigateToCalculator;

  const BudgetScreen({
    super.key,
    this.id,
    required this.navigateToDate,
    required this.navigateToCalculator,
  });

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      ref.listen(budgetFormProvider(id), (previous, next) {
        if (next is! AsyncData<BudgetFormState>) return;

        final previousStatus = previous is AsyncData<BudgetFormState>
            ? previous.value.status
            : null;

        switch (next.value.status) {
          case .success when previousStatus != .success:
            context.pop();
          case .failure when previousStatus != .failure:
            showToastWidget(
              context: context,
              title: 'Opps',
              type: .failure,
              description: next.value.message,
            );
          default:
            break;
        }
      });

      final asyncState = ref.watch(budgetFormProvider(id));

      return ScaffoldWidget(
        appBar: AppBarWidget(leading: GoBackWidget()),
        child: switch (asyncState) {
          AsyncLoading() => const Center(
            child: CircularProgressIndicatorWidget(),
          ),
          AsyncError() => _buildError(context, ref),
          AsyncData(:final value) => _buildForm(context, ref, value),
        },
      );
    },
  );

  Widget _buildError(BuildContext context, WidgetRef ref) => Padding(
    padding: const .all(16.0),
    child: Center(
      child: Column(
        spacing: 16.0,
        mainAxisSize: .min,
        crossAxisAlignment: .center,
        children: [
          Text(
            'Não foi possível carregar o orçamento.',
            textAlign: .center,
            style: context.typography.titleMedium?.copyWith(fontWeight: .bold),
          ),
          ButtonWidget.text(
            label: 'Tentar novamente',
            onTap: () => ref.invalidate(budgetByIdProvider(id!)),
          ),
        ],
      ),
    ),
  );

  Widget _buildForm(
    BuildContext context,
    WidgetRef ref,
    BudgetFormState state,
  ) {
    final notifier = ref.read(budgetFormProvider(id).notifier);
    final isEditing = state.id != null;
    final title = isEditing ? 'Editar orçamento' : 'Novo orçamento';
    final subtitle = isEditing
        ? 'Atualize as informações do seu orçamento.'
        : 'Preencha as informações abaixo para criar um novo orçamento e acompanhar seus gastos.';

    return Padding(
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
                  BudgetAmountFieldWidget(
                    value: state.value,
                    failure: state.valueFailure,
                    navigateTo: () => navigateToCalculator(
                      (cent) => notifier.dispatch(ValueChanged(cent)),
                    ),
                  ),
                  BudgetDescriptionFieldWidget(
                    initialValue: state.description,
                    failure: state.descriptionFailure,
                    onChanged: (value) =>
                        notifier.dispatch(DescriptionChanged(value)),
                  ),
                  BudgetDateFieldWidget(
                    endDate: state.endDate,
                    startDate: state.startDate,
                    failure: state.dateFailure,
                    navigateTo: () => navigateToDate(
                      initialStartDate: state.startDate,
                      initialEndDate: state.endDate,
                      onSelected: (start, end) => notifier.dispatch(
                        DateRangeChanged(startDate: start, endDate: end),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isEditing)
            BudgetEditActionsWidget(
              isLoading: state.status == .loading,
              isDeleting: state.isDeleting,
              onUpdate: () {
                hideKeyboard();
                notifier.dispatch(const SubmitPressed());
              },
              onDelete: () async {
                hideKeyboard();
                final confirmed = await showConfirmDialog(
                  context: context,
                  confirmLabel: 'Excluir',
                  title: 'Excluir orçamento',
                  description: 'Esta ação não pode ser desfeita.',
                );
                if (!confirmed) return;
                notifier.dispatch(const DeletePressed());
              },
            )
          else
            BudgetSaveButtonWidget(
              label: 'Cadastrar',
              isLoading: state.status == .loading,
              onSave: () {
                hideKeyboard();
                notifier.dispatch(const SubmitPressed());
              },
            ),
        ],
      ),
    );
  }
}
