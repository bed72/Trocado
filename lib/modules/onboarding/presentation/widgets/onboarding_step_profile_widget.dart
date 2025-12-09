import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/profile/footer_profile_widget.dart';

class OnboardingStepProfileWidget extends StatelessWidget {
  final bool didSaveData;
  final VoidCallback onEdit;
  final VoidCallback onFinish;

  final String? resource;
  final ValueChanged<String>? onSaved;

  const OnboardingStepProfileWidget({
    super.key,
    required this.onEdit,
    required this.onFinish,
    required this.didSaveData,
    this.onSaved,
    this.resource,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: .only(bottom: context.bottom + 24),
          child: Column(
            spacing: 16.0,
            mainAxisSize: .min,
            children: [
              UserImageWidget(
                onEdit: onEdit,
                resource: resource,
                iconOnEdit: LucideIcons.pencil,
                iconEmpty: LucideIcons.userRound,
              ),

              const StepTitleWidget(value: 'Como podemos te chamar?'),

              StepDescriptionWidget(
                highlight: 'Trocado.',
                value:
                    'Escolha um nome ou apelido. Ele será usado para identificar você '
                    'nas suas interações e histórico dentro do Trocado.',
                highlightStyle: context.typography.bodyLarge?.copyWith(
                  fontWeight: .w600,
                  color: context.colors.inverseSurface.withValues(alpha: 0.82),
                ),
              ),

              FooterProfileWidget(
                onSaved: onSaved,
                onFinish: onFinish,
                didSaveData: didSaveData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
