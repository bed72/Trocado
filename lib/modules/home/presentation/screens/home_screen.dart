import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/presentation/states/transaction_state.dart';
import 'package:trocado/modules/home/presentation/widgets/balance/grid_balance_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_header_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';

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
    child: IconWidget(name: Icons.add),
  );

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const .symmetric(horizontal: 16.0, vertical: 8.0),
          sliver: SliverToBoxAdapter(child: GridBalanceWidget()),
        ),

        SliverPersistentHeader(
          pinned: true,
          delegate: TransactionHeaderWidget(title: 'Transações recentes'),
        ),

        SliverPadding(
          padding: const .symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => TransactionWidget(state: mockTransactions[index]),
              childCount: mockTransactions.length,
            ),
          ),
        ),
      ],
    );
  }
}

final mockTransactions = [
  TransactionState(
    label: 'Salário',
    amount: 'R\$ 7.000,00',
    type: .income,
    category: .salary,
  ),
  TransactionState(
    label: 'Freelance',
    amount: 'R\$ 2.500,00',
    type: .income,
    category: .freelance,
  ),
  TransactionState(
    label: 'Bônus',
    amount: 'R\$ 1.200,00',
    type: .income,
    category: .bonus,
  ),
  TransactionState(
    label: 'Mercado',
    amount: 'R\$ 320,45',
    type: .expense,
    category: .food,
  ),
  TransactionState(
    label: 'Café',
    amount: 'R\$ 18,90',
    type: .expense,
    category: .food,
  ),
  TransactionState(
    label: 'Uber',
    amount: 'R\$ 42,00',
    type: .expense,
    category: .transport,
  ),
  TransactionState(
    label: 'Internet',
    amount: 'R\$ 129,90',
    type: .expense,
    category: .bills,
  ),
  TransactionState(
    label: 'Netflix',
    amount: 'R\$ 39,90',
    type: .expense,
    category: .subscription,
  ),
  TransactionState(
    label: 'Academia',
    amount: 'R\$ 89,90',
    type: .expense,
    category: .health,
  ),
  TransactionState(
    label: 'Livro',
    amount: 'R\$ 75,00',
    type: .expense,
    category: .education,
  ),
  TransactionState(
    label: 'Presente',
    amount: 'R\$ 300,00',
    type: .income,
    category: .gift,
  ),
  TransactionState(
    label: 'Investimentos',
    amount: 'R\$ 210,00',
    type: .income,
    category: .investment,
  ),
];
