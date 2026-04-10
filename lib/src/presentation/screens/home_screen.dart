import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:trocado/src/presentation/mixins/back_button_mixin.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/empty/empty_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_success_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_action_button_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback navigateToExit;
  final VoidCallback navigateToBudget;
  final VoidCallback navigateToCreateExpense;
  final ValueChanged<int?> navigateToChangeExpense;

  const HomeScreen({
    super.key,
    required this.navigateToExit,
    required this.navigateToBudget,
    required this.navigateToCreateExpense,
    required this.navigateToChangeExpense,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with BackButtonMixin<HomeScreen> {
  @override
  void execute() {
    widget.navigateToExit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Despesas do mês'),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: HomeActionButtonWidget(
        onNavigateToBudget: widget.navigateToBudget,
        onNavigateToExpense: widget.navigateToCreateExpense,
      ),
      body: SafeArea(
        child: BlocBuilder<ExpenseListBloc, ExpenseListState>(
          builder: (_, state) => switch (state.status) {
            .initial ||
            .loading => const Center(child: CircularProgressIndicator()),
            .failure => Center(
              child: Column(
                mainAxisSize: .min,
                children: [
                  Text(
                    state.failureMessage ?? 'Ops, algo deu errado.',
                    style: context.typography.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        widget.bloc.add(const ExpenseListRefreshRequested()),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
            .loaded =>
              state.expenses.isEmpty
                  ? EmptyWidget(type: .expense)
                  : HomeSuccessWidget(
                      data: state,
                      navigatTo: widget.navigateToChangeExpense,
                    ),
          },
        ),
      ),
    );
  }
}
