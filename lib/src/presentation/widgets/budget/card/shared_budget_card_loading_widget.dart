import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/presentation/data/budget/shared_budget_card_presentation_data.dart';

import 'package:trocado/src/presentation/widgets/budget/card/shared_budget_card_success_widget.dart';

class SharedBudgetCardLoadingWidget extends StatelessWidget {
  const SharedBudgetCardLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      Skeletonizer(child: const SharedBudgetCardSuccessWidget(data: _placeholder));
}

const _mySlice = MyBudgetSlicePresentationData(
  percentage: 0.4,
  formattedValue: 'R\$ 2.500,00',
  formattedSpent: 'R\$ 1.000,00',
  formattedRemaining: 'R\$ 1.500,00',
);

const _partnerSlice = PartnerBudgetSlicePresentationData(
  percentage: 0.6,
  partnerName: 'Parceiro',
  formattedValue: 'R\$ 5.000,00',
  formattedSpent: 'R\$ 3.000,00',
  formattedRemaining: 'R\$ 2.000,00',
);

const _placeholder = SharedBudgetCardPresentationData(
  overspent: false,
  percentage: 0.5,
  mySlice: _mySlice,
  partnerSlice: _partnerSlice,
  formattedPercentage: '53',
  formattedEndDate: '31 de Mai',
  formattedOverspent: 'R\$ 0,00',
  formattedTotal: 'R\$ 7.500,00',
  formattedSpent: 'R\$ 4.000,00',
  formattedDailyBudget: 'R\$ 230,00',
  formattedRemaining: 'R\$ 3.500,00',
  partnerHasDifferentPeriod: false,
);
