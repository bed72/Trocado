import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:trocado/src/presentation/mixins/back_button_mixin.dart';

import 'package:trocado/src/presentation/widgets/home/home_action_button_widget.dart';

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
      body: Placeholder(),
    );
  }
}
