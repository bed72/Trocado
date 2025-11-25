import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class TypeTransactionScreen extends StatelessWidget {
  final String title;

  const TypeTransactionScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(),
      body: SafeArea(child: Center(child: Text(title))),
    );
  }
}
