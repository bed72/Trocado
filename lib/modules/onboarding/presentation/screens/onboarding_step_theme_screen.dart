import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_navigation_buttons_widget.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_box_decoration_widget.dart';

class OnboardingStepThemeScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback toggle;
  final VoidCallback goBack;
  final VoidCallback goNext;

  const OnboardingStepThemeScreen({
    super.key,
    required this.isDark,
    required this.toggle,
    required this.goBack,
    required this.goNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const .only(left: 24.0, top: 24.0, right: 24.0, bottom: 8.0),
          child: Column(
            spacing: 8.0,
            children: [_buildContent(), _buildButtons()],
          ),
        ),
      ),
    );
  }

  Expanded _buildContent() => Expanded(
    child: Column(
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

        AnimatedSwitcher(
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeInOut,
          duration: Duration(milliseconds: 800),
          child: StepButtonWidget(
            onTap: toggle,
            key: ValueKey(isDark),
            label: isDark ? 'Mudar para tema claro' : 'Mudar para tema escuro',
          ),
        ),
      ],
    ),
  );

  StepNavigationButtonsWidget _buildButtons() =>
      StepNavigationButtonsWidget(goBack: goBack, goNext: goNext);
}
