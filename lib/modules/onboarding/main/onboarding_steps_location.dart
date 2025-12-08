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
    final userStore = context.get<UserStore>();
    final themeStore = context.get<ThemeStore>();

    return OnboardingStepsScreen(
      children: [
        OnboardingStepThemeWidget(
          onToggleThemes: () => themeStore.toggle(!themeStore.isDark),
        ),

        Observer(
          builder: (_) => OnboardingStepProfileWidget(
            resource: userStore.user.image,
            onEdit: () => context.navigate(ImagesLocation()),
            onSaved: (name) => userStore.insert(
              UserDto(name: name, image: userStore.user.image),
            ),
          ),
        ),

        SizedBox(),
      ],
    );
  };
}
