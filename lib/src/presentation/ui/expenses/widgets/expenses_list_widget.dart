import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/presentation/widgets/bounce_widget.dart';

import 'package:trocado/src/presentation/widgets/expense/expense_item_widget.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_state.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_group_model.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_date_header_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_load_more_failure_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_load_more_loading_widget.dart';

class ExpensesListWidget extends StatelessWidget {
  final ExpensesState state;
  final VoidCallback onLoadMore;
  final List<ExpenseGroup> groups;
  final ValueChanged<ExpenseModel> onTapExpense;

  const ExpensesListWidget({
    super.key,
    required this.state,
    required this.groups,
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

            return BounceWidget.withOnPress(
              onPress: () => onTapExpense(item.expense),
              child: ExpenseItemWidget(
                key: ValueKey(item.expense.id),
                expense: item.expense,
                formattedValue: item.formattedValue,
              ),
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
