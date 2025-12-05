import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/images/images.dart';

import 'package:trocado/modules/onboarding/presentation/screens/onboarding_steps_screen.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/onboarding_step_theme_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/onboarding_step_profile_widget.dart';

final class OnboardingStepsLocation extends Location {
  @override
  String get path => RoutesConstant.onboardingSteps.path;

  @override
  LocationBuilder? get builder => (context) {
    final store = context.get<ThemeStore>();

    return OnboardingStepsScreen(
      children: [
        Observer(
          builder: (_) => OnboardingStepThemeWidget(
            isDark: store.isDark,
            onToggleThemes: () => store.toggle(!store.isDark),
          ),
        ),

        OnboardingStepProfileWidget(
          onEdit: () => context.navigate(ImagesLocation()),
        ),
        SizedBox(),
      ],
    );
  };
}
