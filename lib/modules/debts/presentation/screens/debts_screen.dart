import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Dívidas'),
      body: SafeArea(child: Center(child: Text('Debts'))),
    );
  }
}
