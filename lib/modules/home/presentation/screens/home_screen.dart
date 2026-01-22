import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/presentation/widgets/balance/grid_balance_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_header_widget.dart';

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
              (_, index) => TransactionWidget(dto: mockTransactions[index]),
              childCount: mockTransactions.length,
            ),
          ),
        ),
      ],
    );
  }
}

final mockTransactions = [
  TransactionDto(
    description: 'Salário',
    amount: 7000.00,
    type: .income,
    category: .salary,
    date: DateTime(2025, 1, 5),
  ),
  TransactionDto(
    description: 'Freelance',
    amount: 2500.00,
    type: .income,
    category: .freelance,
    date: DateTime(2025, 1, 8),
  ),
  TransactionDto(
    description: 'Bônus',
    amount: 1200.00,
    type: .income,
    category: .bonus,
    date: DateTime(2025, 1, 10),
  ),
  TransactionDto(
    description: 'Mercado',
    amount: 320.45,
    type: .expense,
    category: .food,
    date: DateTime(2025, 1, 12),
  ),
  TransactionDto(
    description: 'Café',
    amount: 18.90,
    type: .expense,
    category: .food,
    date: DateTime(2025, 1, 13),
  ),
  TransactionDto(
    description: 'Uber',
    amount: 42.00,
    type: .expense,
    category: .transport,
    date: DateTime(2025, 1, 14),
  ),
  TransactionDto(
    description: 'Internet',
    amount: 129.90,
    type: .expense,
    category: .bills,
    date: DateTime(2025, 1, 15),
  ),
  TransactionDto(
    description: 'Netflix',
    amount: 39.90,
    type: .expense,
    category: .subscription,
    date: DateTime(2025, 1, 16),
  ),
  TransactionDto(
    description: 'Academia',
    amount: 89.90,
    type: .expense,
    category: .health,
    date: DateTime(2025, 1, 17),
  ),
  TransactionDto(
    description: 'Livro',
    amount: 75.00,
    type: .expense,
    category: .education,
    date: DateTime(2025, 1, 18),
  ),
  TransactionDto(
    description: 'Presente',
    amount: 300.00,
    type: .income,
    category: .gift,
    date: DateTime(2025, 1, 20),
  ),
  TransactionDto(
    description: 'Investimentos',
    amount: 210.00,
    type: .income,
    category: .investment,
    date: DateTime(2025, 1, 22),
  ),
];
