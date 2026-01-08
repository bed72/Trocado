import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/stores/onboarding_store.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/forms/profile_form_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_navigation_buttons_widget.dart';

class OnboardingStepProfileScreen extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback goBack;
  final VoidCallback goNext;
  final VoidCallback navigateToWallet;

  const OnboardingStepProfileScreen({
    super.key,
    required this.goBack,
    required this.goNext,
    required this.onEdit,
    required this.navigateToWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const .only(left: 24.0, top: 24.0, right: 24.0, bottom: 8.0),
          child: Column(
            mainAxisSize: .min,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: .only(bottom: context.bottom + 24),
                    child: _buildContent(context),
                  ),
                ),
              ),

              Observer(
                builder: (context) {
                  final store = context.get<OnboardingStore>();

                  return SlideAnimation(
                    condition: store.user.isLoading,
                    child: _buildButtons(),
                  );
                },
              ),
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
      Observer(
        builder: (context) {
          final store = context.get<OnboardingStore>();

          return UserImageWidget(
            onEdit: onEdit,
            iconOnEdit: LucideIcons.pencil,
            resource: store.user.user.image,
            iconEmpty: LucideIcons.userRound,
          );
        },
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

      ProfileFormWidget(navigateToWallet: navigateToWallet),
    ],
  );

  StepNavigationButtonsWidget _buildButtons() =>
      StepNavigationButtonsWidget(goBack: goBack, goNext: goNext);
}
