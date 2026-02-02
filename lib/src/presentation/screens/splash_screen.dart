import 'dart:async';

import 'package:flutter/material.dart';

import 'package:trocado/src/domain/constants/assets_constant.dart';

import 'package:trocado/src/presentation/actions/callback_action.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/images/image_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

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

    addPostFrameCallback(() async {
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
