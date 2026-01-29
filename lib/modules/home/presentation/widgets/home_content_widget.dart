import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';
import 'package:trocado/modules/home/presentation/widgets/home_failure_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/home_loading_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/home_success_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/home_listener_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/balance/grid_balance_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_header_widget.dart';

class HomeContentWidget extends StatelessWidget {
  final DateCubit dateCubit;
  final HomeCubit homeCubit;
  final ValueChanged<int?> onPress;
  final TransactionCubit transactionCubit;

  const HomeContentWidget({
    super.key,
    required this.onPress,
    required this.dateCubit,
    required this.homeCubit,
    required this.transactionCubit,
  });

  @override
  Widget build(BuildContext context) {
    return HomeListenerWidget(
      dateCubit: dateCubit,
      homeCubit: homeCubit,
      transactionCubit: transactionCubit,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const .symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: GridBalanceWidget(cubit: homeCubit),
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: TransactionHeaderWidget(title: 'Transações recentes'),
          ),

          BlocBuilder<HomeCubit, HomeState>(
            bloc: homeCubit,
            builder: (_, state) => switch (state) {
              HomeFailure() => const HomeTransactionFailureWidget(),
              HomeSuccess() => HomeTransactionSuccessWidget(
                data: state.home,
                onPress: onPress,
                type: state.type,
                format: homeCubit.format,
                onLoadMore: homeCubit.loadMore,
                toDto: homeCubit.toTransactionDto,
                isLoadingMore: state.isLoadingMore,
                hasReachedEnd: state.hasReachedEnd,
                onDelete: (id) => homeCubit.deleteTransactionBy(id: id),
              ),
              HomeIdle() ||
              HomeLoading() => const HomeTransactionLoadingWidget(),
            },
          ),
        ],
      ),
    );
  }
}
