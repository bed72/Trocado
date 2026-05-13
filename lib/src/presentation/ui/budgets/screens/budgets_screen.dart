import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';

import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_state.dart';
import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_notifier.dart';
import 'package:trocado/src/presentation/ui/budgets/widgets/budgets_list_widget.dart';
import 'package:trocado/src/presentation/ui/budgets/widgets/budgets_empty_widget.dart';
import 'package:trocado/src/presentation/ui/budgets/widgets/budgets_failure_widget.dart';
import 'package:trocado/src/presentation/ui/budgets/widgets/budgets_loading_widget.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/budget_card_success_widget.dart';

class BudgetsScreen extends StatefulWidget {
  final ValueChanged<BudgetModel> onTapBudget;

  const BudgetsScreen({super.key, required this.onTapBudget});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  VoidCallback _onLoadMore = () {};

  final double _loadMoreThreshold = 200.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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
      ref.listen(budgetsProvider, (previous, next) {
        final nextDeleteFailure = next.value?.deleteFailure;
        final previousDeleteFailure = previous?.value?.deleteFailure;

        if (nextDeleteFailure != null &&
            nextDeleteFailure != previousDeleteFailure) {
          showToastWidget(
            context: context,
            title: 'Opps',
            type: .failure,
            description: nextDeleteFailure.message,
          );
        }
      });

      final state = ref.watch(budgetsProvider);
      final notifier = ref.read(budgetsProvider.notifier);
      _onLoadMore = notifier.loadMore;

      return Scaffold(
        appBar: const AppBarWidget(leading: GoBackWidget()),
        body: RefreshIndicator(
          onRefresh: () async => ref.invalidate(budgetsProvider),
          child: Padding(
            padding: const .only(bottom: 16.0),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: .symmetric(horizontal: 18.0, vertical: 8.0),
                    child: ScreenHeaderWidget(
                      title: 'Orçamentos',
                      description:
                          'Acompanhe seus orçamentos atuais e passados.',
                    ),
                  ),
                ),
                ..._contentSlivers(ref, state),
              ],
            ),
          ),
        ),
      );
    },
  );

  List<Widget> _contentSlivers(
    WidgetRef ref,
    AsyncValue<BudgetsState> state,
  ) => switch (state) {
    AsyncLoading() => const [SliverToBoxAdapter(child: BudgetsLoadingWidget())],
    AsyncError() => [
      SliverFillRemaining(
        hasScrollBody: false,
        child: BudgetsFailureWidget(
          onRetry: () => ref.invalidate(budgetsProvider),
        ),
      ),
    ],
    AsyncData(:final BudgetsState value)
        when value.activeCard == null && value.items.isEmpty =>
      const [
        SliverFillRemaining(hasScrollBody: false, child: BudgetsEmptyWidget()),
      ],
    AsyncData(:final BudgetsState value) => [
      if (value.activeCard != null && value.activeBudget != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const .all(16.0),
            child: BudgetCardSuccessWidget(
              data: value.activeCard!,
              onTap: () => widget.onTapBudget(value.activeBudget!),
            ),
          ),
        ),
      BudgetsListWidget(
        state: value,
        onLoadMore: _onLoadMore,
        onTapBudget: widget.onTapBudget,
        onDelete: ref.read(budgetsProvider.notifier).deleteById,
      ),
    ],
  };
}
