import 'package:flutter/material.dart';

class PreviewWidget extends StatelessWidget {
  final Widget child;
  final bool? withScaffold;

  const PreviewWidget({super.key, required this.child, this.withScaffold});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: (withScaffold ?? true)
          ? Scaffold(body: SafeArea(child: child))
          : child,
    );
  }
}
