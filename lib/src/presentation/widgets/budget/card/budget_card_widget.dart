import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/data/budget/budget_card_presentation_data.dart';

import 'package:trocado/src/presentation/widgets/budget/card/budget_card_empty_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/budget_card_loading_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/budget_card_failure_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/budget_card_success_widget.dart';

class BudgetCardWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onCreateBudget;
  final VoidCallback? onTap;
  final AsyncValue<BudgetCardPresentationData?> state;

  const BudgetCardWidget({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onCreateBudget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => switch (state) {
    AsyncLoading() => BudgetCardLoadingWidget(),
    AsyncError() => BudgetCardFailureWidget(onRetry: onRetry),
    AsyncData(:final value) when value == null => BudgetCardEmptyWidget(
      onCreateBudget: onCreateBudget,
    ),
    AsyncData(:final value) => BudgetCardSuccessWidget(
      data: value!,
      onTap: onTap,
    ),
  };
}
