import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';

@Preview(name: 'Transaction • Income')
Widget transactionIncomePreview() {
  return PreviewWidget(
    child: TransactionWidget(
      dto: TransactionDto(
        type: .income,
        amount: 720000,
        date: DateTime.now(),
        category: .freelance,
        description: 'Receita',
      ),
    ),
  );
}
