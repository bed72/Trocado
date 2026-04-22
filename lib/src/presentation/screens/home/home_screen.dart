import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:trocado/src/main/providers/services_provider.dart';

import 'package:trocado/src/presentation/mixins/back_button_mixin.dart';

import 'package:trocado/src/presentation/screens/home/notifiers/user_notifier.dart';
import 'package:trocado/src/presentation/screens/home/notifiers/insights_notifier.dart';
import 'package:trocado/src/presentation/screens/home/notifiers/active_budget_notifier.dart';
import 'package:trocado/src/presentation/screens/home/notifiers/recent_expenses_notifier.dart';

import 'package:trocado/src/presentation/screens/home/widgets/home_action_button_widget.dart';

import 'package:trocado/src/presentation/screens/home/widgets/home_app_bar_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/budget/card/budget_card_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/insights/insights_carousel_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/recent_expenses/recent_expenses_section_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback navigateToChat;
  final VoidCallback navigateToExit;
  final VoidCallback navigateToBudget;
  final VoidCallback navigateToSettings;
  final VoidCallback navigateToNotification;
  final VoidCallback navigateToCreateExpense;
  final ValueChanged<int?> navigateToChangeExpense;

  const HomeScreen({
    super.key,
    required this.navigateToChat,
    required this.navigateToExit,
    required this.navigateToBudget,
    required this.navigateToSettings,
    required this.navigateToNotification,
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
    return Consumer(
      builder: (_, ref, _) {
        final userState = ref.watch(userProvider);
        final insightsState = ref.watch(insightsProvider);
        final budgetState = ref.watch(activeBudgetProvider);
        final recentExpensesState = ref.watch(recentExpensesProvider);
        final moneyService = ref.watch(moneyServiceProvider);

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
                    format: moneyService.format,
                    onRetry: () => ref.refresh(activeBudgetProvider),
                  ),
                ),
                InsightsCarouselWidget(
                  state: insightsState,
                  onRetry: () => ref.refresh(insightsProvider),
                ),
                const SizedBox(height: 16.0),
                RecentExpensesSectionWidget(
                  moneyService: moneyService,
                  state: recentExpensesState,
                  onSeeAll: () {},
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
