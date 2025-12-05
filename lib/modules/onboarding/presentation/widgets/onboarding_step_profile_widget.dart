import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/profile/footer_profile_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/profile/header_profile_widget.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';

class OnboardingStepProfileWidget extends StatelessWidget {
  final VoidCallback onEdit;

  const OnboardingStepProfileWidget({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: .only(bottom: context.bottom + 24),
          child: Column(
            spacing: 16.0,
            mainAxisSize: MainAxisSize.min,
            children: [
              HeaderProfileWidget(onEdit: onEdit),

              const StepTitleWidget(value: 'Como podemos te chamar?'),

              StepDescriptionWidget(
                value:
                    'Escolha um nome ou apelido. Ele será usado para identificar você '
                    'nas suas interações e histórico dentro do Trocado.',
                highlight: 'Trocado.',
                highlightStyle: context.typography.bodyLarge?.copyWith(
                  fontWeight: .w600,
                  color: context.colors.inverseSurface.withValues(alpha: 0.82),
                ),
              ),

              FooterProfileWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
