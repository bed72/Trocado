import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/locations/home_location.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/sign_in_location.dart';
import 'package:trocado/src/presentation/screens/splash/notifiers/splash_notifier.dart';
import 'package:trocado/src/presentation/screens/splash/notifiers/splash_state.dart';

import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/images/image_widget.dart';

import 'package:trocado/src/presentation/constants/assets_constant.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen(splashProvider, (_, SplashState state) {
          switch (state.status) {
            case SplashStatus.authenticated:
              context.navigate(HomeLocation(), root: true, replace: true);
            case SplashStatus.unauthenticated:
              context.navigate(SignInLocation(), root: true, replace: true);
            case SplashStatus.loading:
              break;
          }
        });

        return ScaffoldWidget(
          child: Center(
            child: ImageWidget(
              height: 196.0,
              source: AssetsConstant.logo.source,
              color: context.colors.inversePrimary,
            ),
          ),
        );
      },
    );
  }
}
