import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/toast_widget.dart';

class TransactionsListenerWidget extends StatelessWidget {
  final Widget child;
  final TransactionCubit cubit;

  const TransactionsListenerWidget({
    super.key,
    required this.child,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionCubit, TransactionState>(
      bloc: cubit,
      listenWhen: (_, current) =>
          (current is TransactionSuccess && current.transaction != null)
          ? false
          : true,
      listener: (_, state) => switch (state) {
        TransactionSuccess() => _showSuccessToast(context: context),
        TransactionFailure() => _showFailureToast(
          context: context,
          description: state.failure,
        ),
        _ => {},
      },
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

  void _showSuccessToast({required BuildContext context}) {
    showToastWidget(
      context: context,
      onClose: context.pop,
      title: 'Ihulll, tudo certo.',
      description: 'Já atualizamos sua Home.',
    );
  }
}
