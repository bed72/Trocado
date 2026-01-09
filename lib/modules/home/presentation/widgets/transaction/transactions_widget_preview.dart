import 'package:flutter/material.dart';

import 'package:flutter/widget_previews.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/home/presentation/states/transaction_state.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transactions_widget.dart';

@Preview(name: 'Transactions')
Widget transactionsPreview() {
  return PreviewWidget(child: TransactionsWidget(items: mockTransactions));
}

final mockTransactions = [
  TransactionState(
    label: 'Salário',
    amount: 'R\$ 7.000,00',
    type: .income,
    category: .salary,
  ),
  TransactionState(
    label: 'Freelance',
    amount: 'R\$ 2.500,00',
    type: .income,
    category: .freelance,
  ),
  TransactionState(
    label: 'Bônus',
    amount: 'R\$ 1.200,00',
    type: .income,
    category: .bonus,
  ),
  TransactionState(
    label: 'Mercado',
    amount: 'R\$ 320,45',
    type: .expense,
    category: .food,
  ),
  TransactionState(
    label: 'Café',
    amount: 'R\$ 18,90',
    type: .expense,
    category: .food,
  ),
  TransactionState(
    label: 'Uber',
    amount: 'R\$ 42,00',
    type: .expense,
    category: .transport,
  ),
  TransactionState(
    label: 'Internet',
    amount: 'R\$ 129,90',
    type: .expense,
    category: .bills,
  ),
  TransactionState(
    label: 'Netflix',
    amount: 'R\$ 39,90',
    type: .expense,
    category: .subscription,
  ),
  TransactionState(
    label: 'Academia',
    amount: 'R\$ 89,90',
    type: .expense,
    category: .health,
  ),
  TransactionState(
    label: 'Livro',
    amount: 'R\$ 75,00',
    type: .expense,
    category: .education,
  ),
  TransactionState(
    label: 'Presente',
    amount: 'R\$ 300,00',
    type: .income,
    category: .gift,
  ),
  TransactionState(
    label: 'Investimentos',
    amount: 'R\$ 210,00',
    type: .income,
    category: .investment,
  ),
];
