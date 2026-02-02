import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/cubits/date/date_cubit.dart';

import 'package:trocado/src/presentation/cubits/home/home_cubit.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';
import 'package:trocado/src/presentation/widgets/toast_widget.dart';

class HomeListenerWidget extends StatelessWidget {
  final Widget child;
  final DateCubit dateCubit;
  final HomeCubit homeCubit;
  final TransactionCubit transactionCubit;

  const HomeListenerWidget({
    super.key,
    required this.child,
    required this.dateCubit,
    required this.homeCubit,
    required this.transactionCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeCubit, HomeState>(
          bloc: homeCubit,
          listener: (_, state) => switch (state) {
            HomeFailure() => _showFailureToast(
              context: context,
              description: state.failure,
            ),
            _ => {},
          },
        ),

        BlocListener<HomeCubit, HomeState>(
          bloc: homeCubit,
          listenWhen: (previous, current) =>
              (previous is HomeSuccess && current is HomeSuccess)
              ? previous.month != current.month
              : current is HomeSuccess,
          listener: (_, state) {
            if (state is HomeSuccess) {
              dateCubit.select(
                DateTime.fromMillisecondsSinceEpoch(state.month.startAt),
              );
            }
          },
        ),

        BlocListener<TransactionCubit, TransactionState>(
          bloc: transactionCubit,
          listener: (_, state) => switch (state) {
            TransactionSuccess() => homeCubit.findTransactionBy(),
            _ => {},
          },
        ),
      ],
      child: child,
    );
  }

  void _showFailureToast({
    required BuildContext context,
    required String description,
  }) {
    showToastWidget(
      context: context,
      type: .failure,
      description: description,
      title: 'Ops, algo aconteceu.',
    );
  }
}
