import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_item_widget.dart';
import 'package:trocado/src/presentation/widgets/swipe/swipe_actions_background_widget.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_state.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_group_presentation_data.dart';

import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_date_header_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_load_more_failure_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_load_more_loading_widget.dart';

class ExpensesListWidget extends StatelessWidget {
  final ExpensesState state;
  final VoidCallback onLoadMore;
  final ValueChanged<int> onDelete;
  final ValueChanged<ExpenseModel> onTapExpense;
  final List<ExpenseGroupPresentationData> groups;

  const ExpensesListWidget({
    super.key,
    required this.state,
    required this.groups,
    required this.onDelete,
    required this.onLoadMore,
    required this.onTapExpense,
  });

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      for (final group in groups) ...[
        SliverToBoxAdapter(
          child: ExpensesDateHeaderWidget(label: group.header),
        ),
        SliverList.builder(
          itemCount: group.expenses.length,
          itemBuilder: (_, index) {
            final item = group.expenses[index];
            final isEditable = item.expense.createdByMe ?? true;

            final card = ExpenseItemWidget(
              expense: item.expense,
              authorName: item.authorName,
              formattedDate: item.formattedDate,
              formattedValue: item.formattedValue,
            );

            if (!isEditable) return card;

            return Dismissible(
              key: ValueKey(item.expense.id),
              direction: .horizontal,
              background: SwipeActionsBackgroundWidget.leading(
                icon: Icons.edit_outlined,
                color: context.colors.primary,
                iconColor: context.colors.onPrimary,
              ),
              secondaryBackground: SwipeActionsBackgroundWidget.trailing(
                icon: Icons.delete_outline,
                color: context.colors.error,
                iconColor: context.colors.onError,
              ),
              confirmDismiss: (direction) async {
                if (direction == .startToEnd) {
                  onTapExpense(item.expense);
                  return false;
                }

                return await showConfirmDialog(
                  context: context,
                  confirmLabel: 'Excluir',
                  title: 'Excluir despesa',
                  description:
                      'Esta ação vai excluir a despesa e não pode ser desfeita.',
                );
              },
              onDismissed: (_) => onDelete(item.expense.id),
              child: card,
            );
          },
        ),
      ],
      SliverToBoxAdapter(child: _tail()),
    ],
  );

  Widget _tail() {
    if (state.isLoadingMore) return const ExpensesLoadMoreLoadingWidget();
    if (state.loadMoreFailure != null) {
      return ExpensesLoadMoreFailureWidget(onRetry: onLoadMore);
    }

    return const SizedBox.shrink();
  }
}
