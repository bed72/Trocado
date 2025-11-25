import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/screens/onboarding_screen.dart';

final class OnboardingLocation extends Location {
  @override
  String get path => RoutesConstant.onboarding.path;

  @override
  LocationBuilder? get builder =>
      (_) => OnboardingScreen();
}
