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

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppBarWidget(leading: GoBackWidget()),
    body: SafeArea(
      child: Consumer(
        builder: (_, ref, _) {
          final state = ref.watch(expensesProvider);

          return Column(
            crossAxisAlignment: .start,
            children: [
              const Padding(
                padding: .symmetric(horizontal: 16.0),
                child: ScreenHeaderWidget(
                  title: 'Despesas',
                  description: 'Acompanhe todas as suas despesas.',
                ),
              ),
              const Padding(
                padding: .symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: .end,
                  children: [ExpensesFilterButtonWidget()],
                ),
              ),
              Expanded(
                child: switch (state) {
                  AsyncLoading() => const ExpensesLoadingWidget(),
                  AsyncError() => ExpensesFailureWidget(
                    onRetry: () => ref.invalidate(expensesProvider),
                  ),
                  AsyncData(:final ExpensesState value)
                      when value.items.isEmpty =>
                    const ExpensesEmptyWidget(),
                  AsyncData(:final ExpensesState value) => RefreshIndicator(
                    onRefresh: () async => ref.invalidate(expensesProvider),
                    child: ExpensesListWidget(
                      state: value,
                      groups: buildExpenseGroups(value.items),
                      onLoadMore: () =>
                          ref.read(expensesProvider.notifier).loadMore(),
                    ),
                  ),
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}
