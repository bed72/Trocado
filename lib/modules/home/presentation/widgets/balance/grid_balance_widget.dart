import 'package:flutter/material.dart';

import 'package:trocado/modules/home/presentation/states/balance_state.dart';
import 'package:trocado/modules/home/presentation/widgets/balance/balance_widget.dart';

class GridBalanceWidget extends StatelessWidget {
  const GridBalanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16.0,
      children: [
        BalanceWidget(
          state: BalanceState(label: 'Total', amount: 'R\$ 1.000,00'),
        ),
        Row(
          spacing: 16.0,
          children: [
            Expanded(
              child: BalanceWidget(
                state: BalanceState(
                  type: .income,
                  label: 'Receita',
                  amount: 'R\$ 10.000,00',
                ),
              ),
            ),
            Expanded(
              child: BalanceWidget(
                state: BalanceState(
                  type: .expense,
                  label: 'Despesa',
                  amount: 'R\$ 1.000,00',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
