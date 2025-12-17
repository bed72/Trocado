import 'package:duck_router/duck_router.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/main/locations/onboarding_step_profile_location.dart';
import 'package:trocado/modules/onboarding/presentation/screens/onboarding_step_theme_screen.dart';

final class OnboardingStepThemeLocation extends Location {
  @override
  String get path => RoutesConstant.onboardingStepTheme.path;

  @override
  LocationBuilder? get builder =>
      (context) => Observer(
        builder: (_) => OnboardingStepThemeScreen(
          goBack: context.pop,
          store: context.get<ThemeStore>(),
          goNext: () => context.navigate(OnboardingStepProfileLocation()),
        ),
      );
}
