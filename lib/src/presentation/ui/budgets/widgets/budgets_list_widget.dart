import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';
import 'package:trocado/src/presentation/widgets/swipe/swipe_actions_background_widget.dart';

import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_state.dart';
import 'package:trocado/src/presentation/ui/budgets/widgets/budget_list_item_widget.dart';
import 'package:trocado/src/presentation/ui/budgets/widgets/budgets_load_more_failure_widget.dart';
import 'package:trocado/src/presentation/ui/budgets/widgets/budgets_load_more_loading_widget.dart';

class BudgetsListWidget extends StatelessWidget {
  final BudgetsState state;
  final VoidCallback onLoadMore;
  final ValueChanged<int> onDelete;
  final ValueChanged<BudgetModel> onTapBudget;

  const BudgetsListWidget({
    super.key,
    required this.state,
    required this.onDelete,
    required this.onLoadMore,
    required this.onTapBudget,
  });

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      SliverList.builder(
        itemCount: state.items.length,
        itemBuilder: (_, index) {
          final item = state.items[index];

          return Dismissible(
            key: ValueKey(item.budget.id),
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
                onTapBudget(item.budget);
                return false;
              }

              return await showConfirmDialog(
                context: context,
                confirmLabel: 'Excluir',
                title: 'Excluir orçamento',
                description:
                    'Esta ação vai excluir o orçamento e não pode ser desfeita.',
              );
            },
            onDismissed: (_) => onDelete(item.budget.id),
            child: BudgetListItemWidget(item: item),
          );
        },
      ),
      SliverToBoxAdapter(child: _tail()),
    ],
  );

  Widget _tail() {
    if (state.isLoadingMore) return const BudgetsLoadMoreLoadingWidget();
    if (state.loadMoreFailure != null) {
      return BudgetsLoadMoreFailureWidget(onRetry: onLoadMore);
    }

    return const SizedBox.shrink();
  }
}
