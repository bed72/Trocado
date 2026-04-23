import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/presentation/ui/home/data/budget_card_data.dart';
import 'package:trocado/src/presentation/ui/home/widgets/budget/card/budget_card_success_widget.dart';

class BudgetCardLoadingWidget extends StatelessWidget {
  const BudgetCardLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      Skeletonizer(child: const BudgetCardSuccessWidget(data: _placeholder));
}

const _placeholder = BudgetCardData(
  overspent: false,
  percentage: 0.05,
  formattedPercentage: '7',
  formattedOverspent: 'R\$ 0,00',
  formattedValue: 'R\$ 18.000,00',
  formattedDailyBudget: 'R\$ 560,00',
  formattedRemaining: 'R\$ 16.800,00',
  formattedTotalSpent: 'R\$ 1.200,00',
);
