import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/profile/footer_profile_widget.dart';

class OnboardingStepProfileScreen extends StatelessWidget {
  final bool didSaveData;
  final VoidCallback onEdit;
  final VoidCallback onFinish;

  final VoidCallback goBack;
  final VoidCallback goNext;

  final String? resource;
  final ValueChanged<String>? onSaved;

  const OnboardingStepProfileScreen({
    super.key,
    required this.goBack,
    required this.goNext,
    required this.onEdit,
    required this.onFinish,
    required this.didSaveData,
    this.onSaved,
    this.resource,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const .only(left: 24.0, top: 24.0, right: 24.0, bottom: 8.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: .only(bottom: context.bottom + 24),
                    child: _buildContent(context),
                  ),
                ),
              ),

              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildContent(BuildContext context) => Column(
    spacing: 16.0,
    mainAxisSize: .max,
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
  );

  Row _buildButtons(BuildContext context) => Row(
    spacing: 16.0,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ButtonWidget.outlined(onTap: goBack, label: 'Anterior'),
      ButtonWidget.elevated(onTap: goNext, icon: Text('Próximo')),
    ],
  );
}
