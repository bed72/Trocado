import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/home/presentation/states/balance_state.dart';
import 'package:trocado/modules/home/presentation/widgets/balance/balance_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transactions_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transactions_widget_preview.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToTransaction;

  const HomeScreen({
    super.key,
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
    child: IconWidget(name: LucideIcons.plus),
  );

  Padding _buildContent(BuildContext context) => Padding(
    padding: const .symmetric(vertical: 8.0, horizontal: 16.0),
    child: Column(
      spacing: 16.0,
      children: [
        BalanceWidget(
          state: BalanceState(label: 'Total', amount: 'R\$ 1.000,00'),
        ),

        Row(
          spacing: 16.0,
          children: [
            Expanded(
              child: BalanceWidget(
                state: BalanceState(
                  type: .income,
                  label: 'Receita',
                  amount: 'R\$ 10.000,00',
                ),
              ),
            ),
            Expanded(
              child: BalanceWidget(
                state: BalanceState(
                  type: .expense,
                  label: 'Despesa',
                  amount: 'R\$ 1.000,00',
                ),
              ),
            ),
          ],
        ),

        Expanded(child: TransactionsWidget(items: mockTransactions)),
      ],
    ),
  );
}
