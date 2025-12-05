import 'package:watch_it/watch_it.dart';

import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/screens/onboarding_steps_screen.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/onboarding_step_theme_widget.dart';

final class OnboardingStepsLocation extends Location {
  @override
  String get path => RoutesConstant.onboardingSteps.path;

  @override
  LocationBuilder? get builder => (context) {
    final theme = context.get<ThemeCommand>();
    final isDark = watchValue((ThemeCommand theme) => theme.isDark);

    return OnboardingStepsScreen(
      children: [
        OnboardingStepThemeWidget(
          isDark: isDark,
          onToggleThemes: () => theme.command(!isDark),
        ),

        // ConsumersBuilder(
        //   listenables: [
        //     context.commandOf<UserCommand, UserDto?, UserDto?>(),
        //     context.commandOf<ImageCommand, ImagesConstant, File?>(),
        //   ],
        //   builder: (_) {},
        // builder: (_, user, image) {
        //   return switch (image) {
        //     ImageNotifier() when image.isLoading =>
        //       OnboardingStepNicknameWidget(
        //         isLoading: true,
        //         onEdit: () {},
        //         onChanged: (_) {},
        //       ),

        //     ImageNotifier() when image.hasImage =>
        //       OnboardingStepNicknameWidget(
        //         onChanged: (_) {},
        //         source: image.success?.path,
        //         onEdit: () => context.navigate(ImagesLocation()),
        //       ),

        //     _ => OnboardingStepNicknameWidget(
        //       source: null,
        //       name: user.success?.name,
        //       onEdit: () => context.navigate(ImagesLocation()),
        //       onChanged: (name) => user.insert(
        //         UserDto.build(name: name, image: image.success),
        //       ),
        //     ),
        //   };
        // },
        // ),
        SizedBox(),
      ],
    );
  };
}
