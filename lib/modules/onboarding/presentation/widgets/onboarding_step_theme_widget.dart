import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_box_decoration_widget.dart';

class OnboardingStepThemeWidget extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleThemes;

  const OnboardingStepThemeWidget({
    super.key,
    required this.isDark,
    required this.onToggleThemes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16.0,
      mainAxisAlignment: .center,
      children: [
        StepBoxDecorationWidget(
          width: 100,
          height: 100,
          child: Icon(LucideIcons.sunMoon, size: 50.0),
        ),
        StepTitleWidget(value: 'Primeiro, o básico'),
        StepDescriptionWidget(
          value:
              'Escolha o tema visual que combina melhor com você, '
              'toque no botão abaixo para alternar entre as opções.',
        ),

        const SizedBox(height: 16.0),

        StepButtonWidget(
          onTap: onToggleThemes,
          label: isDark ? 'Mudar para tema claro' : 'Mudar para tema escuro',
        ),
      ],
    );
  }
}
