import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/images/images.dart';

import 'package:trocado/modules/onboarding/presentation/screens/onboarding_steps_screen.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/onboarding_step_theme_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/onboarding_step_nickname_widget.dart';

final class OnboardingStepsLocation extends Location {
  @override
  String get path => RoutesConstant.onboardingSteps.path;

  @override
  LocationBuilder? get builder =>
      (context) => OnboardingStepsScreen(
        children: [
          ConsumerBuilder<ThemeNotifier>(
            notifier: context.get<ThemeNotifier>(),
            builder: (_, theme) => OnboardingStepThemeWidget(
              isDark: theme.isDark,
              onToggleThemes: () => theme.toggle(!theme.isDark),
            ),
          ),

          OnboardingStepNicknameWidget(
            onChanged: (value) {},
            initialValue: '',
            onEdit: () => context.navigate(ImagesLocation()),
          ),
          SizedBox(),
        ],
      );
}
