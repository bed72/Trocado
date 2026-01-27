import 'dart:async';

import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';

import 'package:trocado/modules/home/presentation/widgets/home_app_bar_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/home_content_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/home_action_button_widget.dart';

class HomeScreen extends StatefulWidget {
  final HomeCubit homeCubit;
  final TransactionCubit transactionCubit;

  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToTransaction;
  final ValueChanged<TransactionDto> onPress;

  const HomeScreen({
    super.key,
    required this.onPress,
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
    widget.homeCubit.findTransactionBy();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: HomeAppBarWidget(),
      floatingActionButton: HomeActionButtonWidget(
        onNavigateToTransaction: widget.onNavigateToTransaction,
      ),
      child: HomeContentWidget(
        onPress: widget.onPress,
        homeCubit: widget.homeCubit,
        transactionCubit: widget.transactionCubit,
      ),
    );
  }
}
