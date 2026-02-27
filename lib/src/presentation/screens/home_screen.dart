import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:trocado/src/presentation/mixins/back_button_mixin.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/data/ui/category_presentation_data.dart';
import 'package:trocado/src/presentation/widgets/home/home_action_button_widget.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_event.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_state.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int?> onPress;
  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToBudget;
  final VoidCallback onNavigateToExpense;

  const HomeScreen({
    super.key,
    required this.onPress,
    required this.onNavigateToExit,
    required this.onNavigateToBudget,
    required this.onNavigateToExpense,
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
    return Scaffold(
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: HomeActionButtonWidget(
        onNavigateToBudget: widget.onNavigateToBudget,
        onNavigateToExpense: widget.onNavigateToExpense,
      ),
      body: BlocBuilder<ExpenseListBloc, ExpenseListState>(
        builder: (context, state) => switch (state.status) {
          ExpenseListStatus.initial ||
          ExpenseListStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ExpenseListStatus.error => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage ?? 'Ops, algo deu errado.',
                  style: context.typography.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context
                      .read<ExpenseListBloc>()
                      .add(const ExpenseListRefreshRequested()),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
          ExpenseListStatus.loaded => state.expenses.isEmpty
              ? _buildEmpty(context)
              : _buildList(context, state),
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: context.colors.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma despesa por aqui',
              textAlign: TextAlign.center,
              style: context.typography.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comece adicionando suas despesas que elas vão aparecer aqui.',
              textAlign: TextAlign.center,
              style: context.typography.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ExpenseListState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<ExpenseListBloc>()
            .add(const ExpenseListRefreshRequested());
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
            context
                .read<ExpenseListBloc>()
                .add(const ExpenseListNextPageRequested());
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
                child: Text(
                  'Despesas do mês',
                  style: context.typography.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: state.expenses.length +
                    (state.hasReachedMax ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index >= state.expenses.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final expense = state.expenses[index];
                  final category =
                      CategoryPresentationData.fromName(expense.category);
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    expense.date,
                  );

                  return ListTile(
                    onTap: () => widget.onPress(expense.id),
                    leading: CircleAvatar(
                      backgroundColor: category.color.withValues(alpha: 0.15),
                      child: Icon(category.icon, color: category.color, size: 20),
                    ),
                    title: Text(
                      expense.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                      style: context.typography.bodySmall,
                    ),
                    trailing: Text(
                      'R\$ ${expense.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: context.typography.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
