import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/locations/home_location.dart';

import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/images/image_widget.dart';

import 'package:trocado/src/presentation/constants/assets_constant.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/splash/notifiers/splash_state.dart';
import 'package:trocado/src/presentation/screens/splash/notifiers/splash_notifier.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/sign_in_location.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen(splashProvider, (_, SplashState state) => switch (state.status) {
          SplashStatus.authenticated => _navigatTo(context: context, location: HomeLocation()),
          SplashStatus.unauthenticated => _navigatTo(context: context, location: SignInLocation()),
          SplashStatus.loading => null,
        });

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

  void _navigatTo({required BuildContext context, required Location location}) {
    context.navigate(root: true, replace: true, location);
  }
}
