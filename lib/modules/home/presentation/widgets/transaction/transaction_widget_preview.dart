import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/presentation/states/transaction_state.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';

@Preview(name: 'Transaction • Income')
Widget transactionIncomePreview() {
  return PreviewWidget(
    child: TransactionWidget(
      state: TransactionState(
        type: .income,
        label: 'Receita',
        category: .freelance,
        amount: 'R\$ 10.000,00',
      ),
    ),
  );
}
