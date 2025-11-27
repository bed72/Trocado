import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_box_decoration_widget.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onTap;

  const OnboardingScreen({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Column(
              spacing: 16.0,
              mainAxisSize: .max,
              mainAxisAlignment: .center,
              children: [
                StepBoxDecorationWidget(
                  width: 100.0,
                  height: 100.0,
                  child: ImageWidget(
                    source: AssetsConstant.logo.source,
                    alt:
                        'Logo do Trocado, aplicativo de finanças compartilhadas.',
                  ),
                ),
                StepTitleWidget(value: 'Trocado'),
                StepDescriptionWidget(
                  value:
                      'Organize sua vida financeira de um jeito simples, inteligente e compartilhado.',
                ),
                const SizedBox(height: 16.0),
                StepButtonWidget(
                  onTap: onTap,
                  label: 'Vamos tornar isso um hábito.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
