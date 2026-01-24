import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';

class HomeListenerWidget extends StatelessWidget {
  final Widget child;
  final HomeCubit homeCubit;
  final TransactionCubit transactionCubit;

  const HomeListenerWidget({
    super.key,
    required this.child,
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
        BlocListener<TransactionCubit, TransactionState>(
          bloc: transactionCubit,
          listener: (_, state) => switch (state) {
            TransactionSuccess() => homeCubit.findByPeriod(),
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
