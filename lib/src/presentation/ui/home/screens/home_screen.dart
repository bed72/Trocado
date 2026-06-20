import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:trocado/src/main/providers/services_provider.dart';

import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';

import 'package:trocado/src/presentation/mixins/back_button_mixin.dart';
import 'package:trocado/src/presentation/notifiers/couple_notifier.dart';
import 'package:trocado/src/presentation/widgets/budget/card/budget_card_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/shared_budget_card_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/shared_budget_card_loading_widget.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/insights_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/home_app_bar_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/theme/theme_intent.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/theme/theme_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/shared_active_budget_notifier.dart';

import 'package:trocado/src/presentation/ui/home/widgets/home_app_bar_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/home_action_button_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/insights/insights_carousel_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/recent_expenses/recent_expenses_section_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback navigateToChat;
  final VoidCallback navigateToExit;
  final VoidCallback navigateToBudget;
  final VoidCallback navigateToProfile;
  final VoidCallback navigateToBudgets;
  final VoidCallback navigateToExpenses;
  final VoidCallback navigateToSettings;
  final VoidCallback navigateToNotification;
  final VoidCallback navigateToCreateExpense;

  const HomeScreen({
    super.key,
    required this.navigateToChat,
    required this.navigateToExit,
    required this.navigateToBudget,
    required this.navigateToProfile,
    required this.navigateToBudgets,
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
  bool _quickActionsRegistered = false;

  @override
  void execute() {
    widget.navigateToExit();
  }

  void _registerQuickActions(WidgetRef ref) {
    if (_quickActionsRegistered) return;
    _quickActionsRegistered = true;

    ref
        .read(quickActionServiceProvider)
        .register(
          onBudget: widget.navigateToBudget,
          onExpense: widget.navigateToCreateExpense,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        _registerQuickActions(ref);
        final coupleState = ref.watch(coupleProvider);
        final appBarState = ref.watch(homeAppBarProvider);
        final insightsState = ref.watch(insightsProvider);
        final recentExpensesState = ref.watch(recentExpensesProvider);
        final themeMode = ref
            .watch(themeProvider)
            .maybeWhen(data: (s) => s.mode, orElse: () => ThemeModeEnum.system);

        return Scaffold(
          floatingActionButtonLocation: ExpandableFab.location,
          appBar: HomeAppBarWidget(
            themeMode: themeMode,
            appBarState: appBarState,
            navigateToProfile: widget.navigateToProfile,
            navigateToSettings: widget.navigateToSettings,
            navigateToNotification: widget.navigateToNotification,
            onCycleTheme: () =>
                ref.read(themeProvider.notifier).dispatch(const CycleTheme()),
          ),
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
                  child: _budgetCard(ref, coupleState),
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

  Widget _budgetCard(WidgetRef ref, AsyncValue<Object?> coupleState) =>
      switch (coupleState) {
        AsyncData(value: null) => BudgetCardWidget(
          onTap: widget.navigateToBudgets,
          state: ref.watch(activeBudgetProvider),
          onCreateBudget: widget.navigateToBudget,
          onRetry: () => ref.refresh(activeBudgetProvider),
        ),
        AsyncData() => SharedBudgetCardWidget(
          onTap: widget.navigateToBudgets,
          state: ref.watch(sharedActiveBudgetProvider),
          onRetry: () => ref.refresh(sharedActiveBudgetProvider),
        ),
        _ => const SharedBudgetCardLoadingWidget(),
      };
}
