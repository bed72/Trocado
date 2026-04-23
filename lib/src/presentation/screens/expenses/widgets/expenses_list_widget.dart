import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/expense/expense_item_widget.dart';

import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_state.dart';
import 'package:trocado/src/presentation/screens/expenses/data/expense_group_model.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_date_header_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_load_more_failure_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_load_more_loading_widget.dart';

class ExpensesListWidget extends StatefulWidget {
  final ExpensesState state;
  final VoidCallback onLoadMore;
  final List<ExpenseGroup> groups;

  const ExpensesListWidget({
    super.key,
    required this.state,
    required this.groups,
    required this.onLoadMore,
  });

  @override
  State<ExpensesListWidget> createState() => _ExpensesListWidgetState();
}

class _ExpensesListWidgetState extends State<ExpensesListWidget> {
  static const double _loadMoreThreshold = 200.0;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    controller: _controller,
    slivers: [
      for (final group in widget.groups) ...[
        SliverToBoxAdapter(
          child: ExpensesDateHeaderWidget(label: group.header),
        ),
        SliverList.builder(
          itemCount: group.expenses.length,
          itemBuilder: (_, index) {
            final item = group.expenses[index];

            return ExpenseItemWidget(
              key: ValueKey(item.expense.id),
              expense: item.expense,
              formattedValue: item.formattedValue,
            );
          },
        ),
      ],
      SliverToBoxAdapter(child: _tail()),
    ],
  );

  Widget _tail() {
    if (widget.state.isLoadingMore) {
      return const ExpensesLoadMoreLoadingWidget();
    }
    if (widget.state.loadMoreFailure != null) {
      return ExpensesLoadMoreFailureWidget(onRetry: widget.onLoadMore);
    }

    return const SizedBox.shrink();
  }
}
