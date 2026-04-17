import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/active_budget_model.dart';

import 'package:trocado/src/presentation/screens/budget/widgets/card/budget_card_success_widget.dart';

class BudgetCardLoadingWidget extends StatelessWidget {
  const BudgetCardLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BudgetCardSuccessWidget(
      format: (_) => '',
      model: const ActiveBudgetModel(
        id: 0,
        endDate: 0,
        startDate: 0,
        value: 1800000,
        totalSpent: 120000,
        remaining: 1680000,
        description: 'Orçamento do Mês',
      ),
    );
  }
}
