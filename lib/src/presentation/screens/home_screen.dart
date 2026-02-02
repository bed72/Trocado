import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/cubits/date/date_cubit.dart';

import 'package:trocado/src/presentation/cubits/home/home_cubit.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';
import 'package:trocado/src/presentation/mixins/back_button_mixin.dart';

import 'package:trocado/src/presentation/widgets/home/home_app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_content_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_action_button_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

class HomeScreen extends StatefulWidget {
  final DateCubit dateCubit;
  final HomeCubit homeCubit;
  final TransactionCubit transactionCubit;

  final ValueChanged<int?> onPress;
  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToTransaction;

  const HomeScreen({
    super.key,
    required this.onPress,
    required this.dateCubit,
    required this.homeCubit,
    required this.transactionCubit,
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

    widget.homeCubit.findTransactionBy();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: HomeAppBarWidget(cubit: widget.homeCubit),
      floatingActionButton: HomeActionButtonWidget(
        onNavigateToTransaction: widget.onNavigateToTransaction,
      ),
      child: HomeContentWidget(
        onPress: widget.onPress,
        homeCubit: widget.homeCubit,
        dateCubit: widget.dateCubit,
        transactionCubit: widget.transactionCubit,
      ),
    );
  }
}
