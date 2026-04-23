import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/images/image_widget.dart';

import 'package:trocado/src/presentation/constants/assets_constant.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/splash/notifiers/splash_state.dart';
import 'package:trocado/src/presentation/ui/splash/notifiers/splash_notifier.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback navigateToHome;
  final VoidCallback navigateToSignIn;

  const SplashScreen({
    super.key,
    required this.navigateToHome,
    required this.navigateToSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen(
          splashProvider,
          (_, AsyncValue<SplashStatus> state) => switch (state) {
            AsyncData(:final value) => switch (value) {
              SplashStatus.authenticated => navigateToHome(),
              SplashStatus.unauthenticated => navigateToSignIn(),
            },
            _ => null,
          },
        );

        return _buildBody(context);
      },
    );
  }

  ScaffoldWidget _buildBody(BuildContext context) => ScaffoldWidget(
    child: Center(
      child: ImageWidget(
        height: 196.0,
        source: AssetsConstant.logo.source,
        color: context.colors.inversePrimary,
      ),
    ),
  );
}
