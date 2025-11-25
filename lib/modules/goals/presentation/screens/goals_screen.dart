import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Metas'),
      body: SafeArea(child: Center(child: Text('Goals'))),
    );
  }
}
