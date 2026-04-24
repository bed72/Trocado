import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:trocado/src/presentation/mixins/back_button_mixin.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/user_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/insights_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart';

import 'package:trocado/src/presentation/ui/home/widgets/home_action_button_widget.dart';

import 'package:trocado/src/presentation/ui/home/widgets/home_app_bar_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/budget/card/budget_card_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/insights/insights_carousel_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/recent_expenses/recent_expenses_section_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback navigateToChat;
  final VoidCallback navigateToExit;
  final VoidCallback navigateToBudget;
  final VoidCallback navigateToExpenses;
  final VoidCallback navigateToSettings;
  final VoidCallback navigateToNotification;
  final VoidCallback navigateToCreateExpense;

  const HomeScreen({
    super.key,
    required this.navigateToChat,
    required this.navigateToExit,
    required this.navigateToBudget,
    required this.navigateToExpenses,
    required this.navigateToSettings,
    required this.navigateToNotification,
    required this.navigateToCreateExpense,
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
    return Consumer(
      builder: (_, ref, _) {
        final userState = ref.watch(userProvider);
        final insightsState = ref.watch(insightsProvider);
        final budgetState = ref.watch(activeBudgetProvider);
        final recentExpensesState = ref.watch(recentExpensesProvider);

        return Scaffold(
          appBar: HomeAppBarWidget(
            userState: userState,
            navigateToSettings: widget.navigateToSettings,
            navigateToNotification: widget.navigateToNotification,
          ),
          floatingActionButtonLocation: ExpandableFab.location,
          floatingActionButton: HomeActionButtonWidget(
            onChat: widget.navigateToChat,
            onBudget: widget.navigateToBudget,
            onExpense: widget.navigateToCreateExpense,
          ),
          body: SafeArea(
            child: ListView(
              children: [
                Padding(
                  padding: const .all(16.0),
                  child: BudgetCardWidget(
                    state: budgetState,
                    onCreateBudget: widget.navigateToBudget,
                    onRetry: () => ref.refresh(activeBudgetProvider),
                  ),
                ),
                InsightsCarouselWidget(
                  state: insightsState,
                  onRetry: () => ref.refresh(insightsProvider),
                ),
                const SizedBox(height: 16.0),
                RecentExpensesSectionWidget(
                  state: recentExpensesState,
                  onSeeAll: widget.navigateToExpenses,
                  onRetry: () => ref.refresh(recentExpensesProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
