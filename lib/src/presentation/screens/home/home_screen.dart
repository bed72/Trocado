import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:trocado/src/presentation/mixins/back_button_mixin.dart';

import 'package:trocado/src/presentation/screens/home/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/screens/home/widgets/home_app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_action_button_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback navigateToExit;
  final VoidCallback navigateToBudget;
  final VoidCallback navigateToSettings;
  final VoidCallback navigateToNotification;
  final VoidCallback navigateToCreateExpense;
  final ValueChanged<int?> navigateToChangeExpense;

  const HomeScreen({
    super.key,
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

        return Scaffold(
          appBar: HomeAppBarWidget(
            userState: userState,
            navigateToSettings: widget.navigateToSettings,
            navigateToNotification: widget.navigateToNotification,
          ),
          floatingActionButtonLocation: ExpandableFab.location,
          floatingActionButton: HomeActionButtonWidget(
            onNavigateToBudget: widget.navigateToBudget,
            onNavigateToExpense: widget.navigateToCreateExpense,
          ),
          body: const SafeArea(child: Placeholder()),
        );
      },
    );
  }
}
