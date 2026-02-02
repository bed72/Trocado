import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/mixins/back_button_mixin.dart';

import 'package:trocado/src/presentation/cubits/home/home_cubit.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_failure_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_loading_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_success_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_action_button_widget.dart';
import 'package:trocado/src/presentation/widgets/home/balance/grid_balance_widget.dart';
import 'package:trocado/src/presentation/widgets/home/transaction/transaction_header_widget.dart';

class HomeScreen extends StatefulWidget {
  final HomeCubit cubit;
  final ValueChanged<int?> onPress;
  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToTransaction;

  const HomeScreen({
    super.key,
    required this.cubit,
    required this.onPress,
    required this.onNavigateToExit,
    required this.onNavigateToTransaction,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with BackButtonMixin<HomeScreen> {
  @override
  void execute() {
    widget.onNavigateToExit();
  }

  @override
  void initState() {
    super.initState();

    widget.cubit.findTransactionBy();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: HomeAppBarWidget(cubit: widget.cubit),
      floatingActionButton: HomeActionButtonWidget(
        onNavigateToTransaction: widget.onNavigateToTransaction,
      ),
      child: BlocListener<HomeCubit, HomeState>(
        bloc: widget.cubit,
        listener: (_, state) => switch (state) {
          HomeFailure() => _showFailureToast(state.failure),
          _ => {},
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const .symmetric(horizontal: 16.0),
              sliver: SliverToBoxAdapter(
                child: GridBalanceWidget(cubit: widget.cubit),
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: TransactionHeaderWidget(title: 'Transações recentes'),
            ),

            BlocBuilder<HomeCubit, HomeState>(
              bloc: widget.cubit,
              builder: (_, state) => switch (state) {
                HomeFailure() => const HomeTransactionFailureWidget(),
                HomeSuccess() => HomeTransactionSuccessWidget(
                  data: state.home,
                  onPress: widget.onPress,
                  type: state.type,
                  format: widget.cubit.format,
                  onLoadMore: widget.cubit.loadMore,
                  isLoadingMore: state.isLoadingMore,
                  hasReachedEnd: state.hasReachedEnd,
                  onDelete: (id) => widget.cubit.deleteTransactionBy(id: id),
                ),
                HomeIdle() ||
                HomeLoading() => const HomeTransactionLoadingWidget(),
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFailureToast(String description) {
    showToastWidget(
      type: .failure,
      context: context,
      description: description,
      title: 'Ops, algo aconteceu.',
    );
  }
}
