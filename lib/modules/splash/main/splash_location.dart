import 'package:duck_router/duck_router.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/onboarding/onboarding.dart';

import 'package:trocado/modules/splash/presentation/screens/splash_screen.dart';

final class SplashLocation extends Location {
  @override
  String get path => RoutesConstant.splash.path;

  @override
  LocationBuilder? get builder => (context) {
    final store = context.get<OnboardingStore>();

    return SignalBuilder(
      builder: (_, _) {
        return SplashScreen(
          navigateTo: () {
            context.navigate(
              store.onboarding() ? CoreLocation() : OnboardingLocation(),
              clearStack: true,
            );
          },
        );
      },
    );
  };
}
