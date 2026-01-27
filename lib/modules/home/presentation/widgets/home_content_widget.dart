import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';
import 'package:trocado/modules/home/presentation/widgets/home_failure_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/home_loading_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/home_success_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/home_listener_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/balance/grid_balance_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_header_widget.dart';

class HomeContentWidget extends StatelessWidget {
  final HomeCubit homeCubit;
  final TransactionCubit transactionCubit;
  final ValueChanged<TransactionDto> onPress;

  const HomeContentWidget({
    super.key,
    required this.onPress,
    required this.homeCubit,
    required this.transactionCubit,
  });

  @override
  Widget build(BuildContext context) {
    return HomeListenerWidget(
      homeCubit: homeCubit,
      transactionCubit: transactionCubit,
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
            bloc: homeCubit,
            builder: (_, state) => switch (state) {
              HomeFailure() => const HomeFailureWidget(),
              HomeSuccess() => HomeSuccessWidget(
                data: state.home,
                onPress: onPress,
                toDto: homeCubit.toDto,
                onDelete: homeCubit.deleteTransactionBy,
              ),
              HomeIdle() || HomeLoading() => const HomeLoadingWidget(),
            },
          ),
        ],
      ),
    );
  }
}
