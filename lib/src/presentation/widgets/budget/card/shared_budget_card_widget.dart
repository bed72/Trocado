import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/data/budget/shared_budget_card_presentation_data.dart';

import 'package:trocado/src/presentation/widgets/budget/card/shared_budget_card_empty_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/shared_budget_card_failure_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/shared_budget_card_loading_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/shared_budget_card_success_widget.dart';

class SharedBudgetCardWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback onRetry;
  final AsyncValue<SharedBudgetCardPresentationData?> state;

  const SharedBudgetCardWidget({
    super.key,
    required this.state,
    required this.onRetry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const SharedBudgetCardLoadingWidget();

    return switch (state) {
      AsyncValue(:final value, hasValue: true) when value != null =>
        SharedBudgetCardSuccessWidget(data: value, onTap: onTap),
      AsyncValue(hasValue: true) => const SharedBudgetCardEmptyWidget(),
      AsyncError() => SharedBudgetCardFailureWidget(onRetry: onRetry),
      _ => const SharedBudgetCardLoadingWidget(),
    };
  }
}
