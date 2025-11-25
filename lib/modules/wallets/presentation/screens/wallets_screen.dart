import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(),
      body: SafeArea(child: Center(child: Text('Wallets'))),
    );
  }
}
