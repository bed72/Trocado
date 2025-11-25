import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(),
      body: SafeArea(child: Center(child: Text('All Transactions'))),
    );
  }
}
