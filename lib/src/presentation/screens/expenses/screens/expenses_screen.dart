import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_state.dart';
import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_notifier.dart';

import 'package:trocado/src/presentation/screens/expenses/data/expense_groups_builder.dart';

import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_list_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_empty_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_failure_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_loading_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_filter_button_widget.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  VoidCallback _onLoadMore = () {};

  final double _loadMoreThreshold = 200.0;
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
      _onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppBarWidget(
      leading: GoBackWidget(),
      actions: [
        Padding(
          padding: .only(right: 16.0),
          child: ExpensesFilterButtonWidget(),
        ),
      ],
    ),
    body: Consumer(
      builder: (_, ref, _) {
        final state = ref.watch(expensesProvider);
        _onLoadMore = () => ref.read(expensesProvider.notifier).loadMore();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(expensesProvider),
          child: CustomScrollView(
            controller: _controller,
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
              ..._contentSlivers(ref, state),
            ],
          ),
        );
      },
    ),
  );

  List<Widget> _contentSlivers(
    WidgetRef ref,
    AsyncValue<ExpensesState> state,
  ) => switch (state) {
    AsyncLoading() => const [
      SliverToBoxAdapter(child: ExpensesLoadingWidget()),
    ],
    AsyncError() => [
      SliverFillRemaining(
        hasScrollBody: false,
        child: ExpensesFailureWidget(
          onRetry: () => ref.invalidate(expensesProvider),
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
