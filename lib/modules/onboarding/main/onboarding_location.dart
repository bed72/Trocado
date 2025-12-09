import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/main/onboarding_step_theme_location.dart';
import 'package:trocado/modules/onboarding/presentation/screens/onboarding_screen.dart';

final class OnboardingLocation extends Location {
  @override
  String get path => RoutesConstant.onboarding.path;

  @override
  LocationBuilder? get builder =>
      (context) => OnboardingScreen(
        onTap: () => context.navigate(OnboardingStepThemeLocation()),
      );
}
