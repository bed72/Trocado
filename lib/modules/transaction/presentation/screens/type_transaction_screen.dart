import 'package:flutter/material.dart';

class TypeTransactionScreen extends StatelessWidget {
  final String title;

  const TypeTransactionScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(child: Center(child: Text(title))),
    );
  }
}
