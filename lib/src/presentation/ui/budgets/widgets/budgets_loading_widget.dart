import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';

import 'package:trocado/src/presentation/ui/budgets/widgets/budget_list_item_widget.dart';
import 'package:trocado/src/presentation/ui/budgets/data/budget_item_presentation_data.dart';

class BudgetsLoadingWidget extends StatelessWidget {
  const BudgetsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => Skeletonizer(
    child: Column(
      mainAxisSize: .min,
      children: .generate(
        6,
        (_) => const BudgetListItemWidget(item: _placeholder),
      ),
    ),
  );
}

const _placeholder = BudgetItemPresentationData(
  budget: BudgetModel(
    id: 0,
    value: 0,
    endDate: 0,
    startDate: 0,
    description: 'Carregando descrição do orçamento',
  ),
  formattedValue: 'R\$ 0.000,00',
  formattedPeriod: '00 de Mmm até 00 de Mmm',
  formattedRemaining: 'R\$ 0.000,00',
  formattedTotalSpent: 'R\$ 0.000,00',
);
