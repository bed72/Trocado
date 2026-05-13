import 'package:flutter/material.dart' hide ValueChanged;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';
import 'package:trocado/src/presentation/widgets/circular_progress_indicator_widget.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/expense/notifiers/form/expense_state.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/form/expense_intent.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/form/expense_notifier.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/expense_by_id_notifier.dart';

import 'package:trocado/src/presentation/ui/expense/widgets/expense_date_field_widget.dart';
import 'package:trocado/src/presentation/ui/expense/widgets/expense_save_button_widget.dart';
import 'package:trocado/src/presentation/ui/expense/widgets/expense_amount_field_widget.dart';
import 'package:trocado/src/presentation/ui/expense/widgets/expense_edit_actions_widget.dart';
import 'package:trocado/src/presentation/ui/expense/widgets/expense_description_field_widget.dart';

class ExpenseScreen extends StatelessWidget {
  final int? id;
  final VoidCallback navigateToDate;
  final void Function(void Function(int)) navigateToCalculator;

  const ExpenseScreen({
    super.key,
    this.id,
    required this.navigateToDate,
    required this.navigateToCalculator,
  });

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      ref.listen(expenseProvider(id), (previous, next) {
        if (next is! AsyncData<ExpenseState>) return;

        final previousStatus = previous is AsyncData<ExpenseState>
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

      final asyncState = ref.watch(expenseProvider(id));

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
            'Não foi possível carregar a despesa.',
            textAlign: .center,
            style: context.typography.titleMedium?.copyWith(fontWeight: .bold),
          ),
          ButtonWidget.text(
            label: 'Tentar novamente',
            onTap: () => ref.invalidate(expenseByIdProvider(id!)),
          ),
        ],
      ),
    ),
  );

  Widget _buildForm(BuildContext context, WidgetRef ref, ExpenseState state) {
    final notifier = ref.read(expenseProvider(id).notifier);
    final isEditing = state.id != null;
    final title = isEditing ? 'Editar despesa' : 'Nova despesa';
    final subtitle = isEditing
        ? 'Atualize as informações da sua despesa.'
        : 'Preencha as informações abaixo para registrar sua despesa.';

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
                    failure: state.dateFailure,
                    displayValue: state.formattedDate,
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
              onDelete: () async {
                hideKeyboard();
                final confirmed = await showConfirmDialog(
                  context: context,
                  confirmLabel: 'Excluir',
                  title: 'Excluir despesa',
                  description: 'Esta ação não pode ser desfeita.',
                );
                if (!confirmed) return;
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
    );
  }
}
