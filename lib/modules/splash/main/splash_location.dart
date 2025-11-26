import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/onboarding/onboarding.dart';

import 'package:trocado/modules/splash/presentation/screens/splash_screen.dart';

final class SplashLocation extends Location {
  @override
  String get path => RoutesConstant.splash.path;

  @override
  LocationBuilder? get builder => (context) {
    final notifier = context.get<OnboardingNotifier>();

    return SplashScreen(
      navigateTo: () {
        context.navigate(
          notifier.enabled ? CoreLocation() : OnboardingLocation(),
          clearStack: true,
        );
      },
    );
  };
}
