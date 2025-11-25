import 'dart:async';

import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class SplashScreen extends StatefulWidget {
  final Future<void> Function() navigateToRoot;

  const SplashScreen({super.key, required this.navigateToRoot});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with AfterLayoutMixin {
  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    await Future.delayed(Durations.medium4, widget.navigateToRoot);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: Text('Splash'))),
    );
  }
}
