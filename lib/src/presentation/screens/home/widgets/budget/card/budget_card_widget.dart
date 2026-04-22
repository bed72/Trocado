import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/budget/active_budget_model.dart';

import 'package:trocado/src/presentation/screens/home/widgets/budget/card/budget_card_empty_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/budget/card/budget_card_loading_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/budget/card/budget_card_failure_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/budget/card/budget_card_success_widget.dart';

class BudgetCardWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onCreateBudget;
  final String Function(double) format;
  final AsyncValue<ActiveBudgetModel?> state;

  const BudgetCardWidget({
    super.key,
    required this.state,
    required this.format,
    required this.onRetry,
    required this.onCreateBudget,
  });

  @override
  Widget build(BuildContext context) => switch (state) {
    AsyncLoading() => BudgetCardLoadingWidget(),
    AsyncError() => BudgetCardFailureWidget(onRetry: onRetry),
    AsyncData(:final value) when value == null => BudgetCardEmptyWidget(
      onCreateBudget: onCreateBudget,
    ),
    AsyncData(:final value) => BudgetCardSuccessWidget(
      model: value!,
      format: format,
    ),
  };
}
