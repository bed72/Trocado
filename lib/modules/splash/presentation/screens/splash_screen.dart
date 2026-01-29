import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trocado/modules/core/core.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback navigateTo;

  const SplashScreen({super.key, required this.navigateTo});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Future.delayed(Durations.extralong4);

      widget.navigateTo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      child: Center(
        child: ImageWidget(
          height: 196.0,
          source: AssetsConstant.logo.source,
          color: context.colors.inversePrimary,
        ),
      ),
    );
  }
}
