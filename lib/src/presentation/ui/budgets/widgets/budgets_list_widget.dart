import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_state.dart';
import 'package:trocado/src/presentation/ui/budgets/widgets/budget_list_item_widget.dart';
import 'package:trocado/src/presentation/ui/budgets/widgets/budgets_load_more_failure_widget.dart';
import 'package:trocado/src/presentation/ui/budgets/widgets/budgets_load_more_loading_widget.dart';

class BudgetsListWidget extends StatelessWidget {
  final BudgetsState state;
  final VoidCallback onLoadMore;

  const BudgetsListWidget({
    super.key,
    required this.state,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      SliverList.builder(
        itemCount: state.items.length,
        itemBuilder: (_, index) {
          final item = state.items[index];

          return BudgetListItemWidget(
            key: ValueKey(item.budget.id),
            item: item,
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
