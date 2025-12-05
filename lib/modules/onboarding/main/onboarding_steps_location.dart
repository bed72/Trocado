import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/core/data/dtos/user_dto.dart';
import 'package:trocado/modules/images/images.dart';

import 'package:trocado/modules/onboarding/presentation/screens/onboarding_steps_screen.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/onboarding_step_theme_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/onboarding_step_profile_widget.dart';

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

          ConsumersBuilder<UserNotifier, ImageNotifier>(
            builder: (_, user, image) => switch (image) {
              ImageNotifier() when image.isLoading =>
                OnboardingStepProfileWidget(
                  avatarIsLoading: true,
                  onSaved: (_) {},
                  onEdit: () => context.navigate(ImagesLocation()),
                ),

              _ => OnboardingStepProfileWidget(
                source: image.success?.path,
                nicknameIsLoading: user.isLoading,
                onEdit: () => context.navigate(ImagesLocation()),
                onSaved: (name) => user.insert(
                  UserDto(name: name, image: image.success?.path),
                ),
              ),
            },
          ),
          SizedBox(),
        ],
      );
}
