import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class RecurringTransactionsScreen extends StatelessWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Transações recorrentes'),
      body: SafeArea(child: Center(child: Text('Recurring Transactions'))),
    );
  }
}
