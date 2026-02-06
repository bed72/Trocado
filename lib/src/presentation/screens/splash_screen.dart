import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/infrastructure/providers/providers.dart';

import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/images/image_widget.dart';

import 'package:trocado/src/presentation/constants/assets_constant.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback navigateTo;

  const SplashScreen({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        ref.listen(initialization, (_, next) {
          next.whenOrNull(
            data: (_) async {
              await Future.delayed(Durations.extralong4);
              navigateTo();
            },
          );
        });

        return ScaffoldWidget(
          child: Center(
            child: ImageWidget(
              height: 196,
              source: AssetsConstant.logo.source,
              color: context.colors.inversePrimary,
            ),
          ),
        );
      },
    );
  }
}
