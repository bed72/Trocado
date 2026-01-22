import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/transaction.dart';
import 'package:trocado/modules/home/domain/models/home_model.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';
import 'package:trocado/modules/home/presentation/widgets/balance/grid_balance_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_header_widget.dart';

class HomeScreen extends StatefulWidget {
  final HomeCubit homeCubit;
  final TransactionCubit transactionCubit;

  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToTransaction;

  const HomeScreen({
    super.key,
    required this.homeCubit,
    required this.transactionCubit,
    required this.onNavigateToExit,
    required this.onNavigateToTransaction,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AfterLayoutMixin, BackButtonMixin<HomeScreen> {
  @override
  void execute() {
    widget.onNavigateToExit();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    widget.homeCubit.findByPeriod();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: _buildAppBar(),
      floatingActionButton: _buildFloatingActionButton(),
      child: _buildContent(context),
    );
  }

  AppBar _buildAppBar() => AppBar(
    centerTitle: true,
    toolbarHeight: 72.0,
    title: SelectorWidget(
      selected: 0,
      onSelected: (value) {},
      options: ['Todas', 'Despesas', 'Receitas'],
    ),
  );

  FloatingActionButton _buildFloatingActionButton() => FloatingActionButton(
    onPressed: widget.onNavigateToTransaction,
    child: IconWidget(name: Icons.add),
  );

  Widget _buildContent(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeCubit, HomeState>(
          bloc: widget.homeCubit,
          listener: (_, state) => switch (state) {
            HomeFailure() => _showFailureToast(state.failure),
            _ => {},
          },
        ),
        BlocListener<TransactionCubit, TransactionState>(
          bloc: widget.transactionCubit,
          listener: (_, state) => switch (state) {
            TransactionSuccess() => widget.homeCubit.findByPeriod(),
            _ => {},
          },
        ),
      ],
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const .symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(child: GridBalanceWidget()),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: TransactionHeaderWidget(title: 'Transações recentes'),
          ),

          BlocBuilder<HomeCubit, HomeState>(
            bloc: widget.homeCubit,
            builder: (_, state) => switch (state) {
              HomeIdle() || HomeLoading() => _buildLoading(),
              HomeFailure() => _buildFailure(),
              HomeSuccess() => _buildSuccess(state.home),
            },
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildLoading() => SliverToBoxAdapter(
    child: SkeletonWidget(
      child: Column(
        children: .generate(10, (_) => TransactionWidget(dto: .empty())),
      ),
    ),
  );

  SliverToBoxAdapter _buildFailure() =>
      const SliverToBoxAdapter(child: SizedBox.shrink());

  SliverPadding _buildSuccess(HomeModel data) => SliverPadding(
    padding: const .symmetric(horizontal: 16.0),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: data.transactions.length,
        (_, index) => TransactionWidget(
          dto: widget.homeCubit.toDto(data.transactions[index]),
        ),
      ),
    ),
  );

  void _showFailureToast(String description) {
    showToastWidget(
      context: context,
      type: .failure,
      description: description,
      title: 'Ops, algo aconteceu.',
    );
  }
}
