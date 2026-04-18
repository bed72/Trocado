import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/domain/models/active_budget_model.dart';

import 'package:trocado/src/presentation/screens/home/widgets/budget/card/budget_card_success_widget.dart';

class BudgetCardLoadingWidget extends StatelessWidget {
  const BudgetCardLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: BudgetCardSuccessWidget(
        format: (_) => 'R\$ 0,00',
        model: const ActiveBudgetModel(
          id: 0,
          endDate: 0,
          startDate: 0,
          value: 1800000,
          remaining: 1680000,
          totalSpent: 120000,
          description: 'Orçamento do Mês',
        ),
      ),
    );
  }
}
