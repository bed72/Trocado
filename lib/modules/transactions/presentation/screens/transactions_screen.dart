import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: AppBarWidget(),
      child: Center(child: Text('Transactions')),
    );
  }
}
