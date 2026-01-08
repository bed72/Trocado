import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trocado/modules/core/core.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback navigateTo;

  const SplashScreen({super.key, required this.navigateTo});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with AfterLayoutMixin {
  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    await Future.delayed(Durations.extralong4);

    widget.navigateTo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ImageWidget(height: 200.0, source: AssetsConstant.logo.source),
        ),
      ),
    );
  }
}
