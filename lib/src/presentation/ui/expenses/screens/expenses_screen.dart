import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_state.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';

import 'package:trocado/src/presentation/ui/expenses/data/expense_groups_builder.dart';

import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_list_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_empty_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_failure_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_loading_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_search_field_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_filter_button_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_active_filters_widget.dart';

class ExpensesScreen extends StatefulWidget {
  final ValueChanged<ExpenseFilterModel> navigateToFilter;

  const ExpensesScreen({super.key, required this.navigateToFilter});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  VoidCallback _onLoadMore = () {};

  final double _loadMoreThreshold = 200.0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      final state = ref.watch(expensesProvider);
      final notifier = ref.read(expensesProvider.notifier);
      _onLoadMore = notifier.loadMore;

      return Scaffold(
        appBar: AppBarWidget(
          leading: const GoBackWidget(),
          titleWidget: ExpensesSearchFieldWidget(
            controller: _searchController,
            onChanged: notifier.searchChanged,
            onClear: () {
              _searchController.clear();
              notifier.searchChanged('');
            },
          ),
          actions: [
            Padding(
              padding: const .only(right: 16.0),
              child: ExpensesFilterButtonWidget(
                onPress: () => widget.navigateToFilter(
                  state.value?.filter ?? const ExpenseFilterModel.empty(),
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => notifier.applyFilter(
            state.value?.filter ?? const ExpenseFilterModel.empty(),
          ),
          child: Padding(
            padding: const .only(bottom: 16.0),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: .symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ScreenHeaderWidget(
                      title: 'Despesas',
                      description: 'Acompanhe todas as suas despesas.',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ExpensesActiveFiltersWidget(
                    onRemove: notifier.removeFilter,
                    chips: state.value?.activeFilterChips ?? const [],
                  ),
                ),
                ..._contentSlivers(notifier, state),
              ],
            ),
          ),
        ),
      );
    },
  );

  List<Widget> _contentSlivers(
    ExpensesNotifier notifier,
    AsyncValue<ExpensesState> state,
  ) => switch (state) {
    AsyncLoading() => const [
      SliverToBoxAdapter(child: ExpensesLoadingWidget()),
    ],
    AsyncError() => [
      SliverFillRemaining(
        hasScrollBody: false,
        child: ExpensesFailureWidget(
          onRetry: () => notifier.applyFilter(const ExpenseFilterModel.empty()),
        ),
      ),
    ],
    AsyncData(:final ExpensesState value) when value.items.isEmpty => const [
      SliverFillRemaining(hasScrollBody: false, child: ExpensesEmptyWidget()),
    ],
    AsyncData(:final ExpensesState value) => [
      ExpensesListWidget(
        state: value,
        onLoadMore: _onLoadMore,
        groups: buildExpenseGroups(value.items),
      ),
    ],
  };
}
