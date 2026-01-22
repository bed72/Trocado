import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/data/dtos/balance_dto.dart';
import 'package:trocado/modules/home/presentation/widgets/balance/balance_widget.dart';

@Preview(name: 'Balance • Income', group: 'Balance')
Widget balanceIncomePreview() {
  return PreviewWidget(
    child: BalanceWidget(
      state: BalanceDto(
        type: .income,
        label: 'Receita',
        amount: 'R\$ 10.000,00',
      ),
    ),
  );
}

@Preview(name: 'Balance • Expense', group: 'Balance')
Widget balanceExpensePreview() {
  return PreviewWidget(
    child: BalanceWidget(
      state: BalanceDto(
        type: .expense,
        label: 'Despesa',
        amount: 'R\$ 1.000,00',
      ),
    ),
  );
}

@Preview(name: 'Balance • Total', group: 'Balance')
Widget balanceTotalPreview() {
  return PreviewWidget(
    child: BalanceWidget(
      state: BalanceDto(label: 'Total', amount: 'R\$ 1.000,00'),
    ),
  );
}
