import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/forms/profile_form_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_navigation_buttons_widget.dart';

class OnboardingStepProfileScreen extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onEdit;

  final VoidCallback goBack;
  final VoidCallback goNext;

  final String? resource;
  final ValueChanged<String>? onSaved;

  const OnboardingStepProfileScreen({
    super.key,
    required this.goBack,
    required this.goNext,
    required this.onEdit,
    required this.isLoading,
    this.onSaved,
    this.resource,
  });

  @override
  State<OnboardingStepProfileScreen> createState() =>
      _OnboardingStepProfileScreenState();
}

class _OnboardingStepProfileScreenState
    extends State<OnboardingStepProfileScreen> {
  late bool _hideButtons;

  @override
  void initState() {
    super.initState();

    _hideButtons = false;
  }

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
                    child: _buildContent(),
                  ),
                ),
              ),

              KeyboardVisibilityWidget(
                onChanged: _handleKeyboardVisibility,
                child: AnimatedSlide(
                  curve: Curves.decelerate,
                  duration: const Duration(milliseconds: 300),
                  offset: _hideButtons ? const Offset(0, 1) : .zero,
                  child: AnimatedOpacity(
                    opacity: _hideButtons ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: _buildButtons(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildContent() => Column(
    spacing: 16.0,
    mainAxisSize: .max,
    children: [
      UserImageWidget(
        onEdit: widget.onEdit,
        resource: widget.resource,
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

      ProfileFormWidget(onSaved: widget.onSaved, isLoading: widget.isLoading),
    ],
  );

  StepNavigationButtonsWidget _buildButtons() =>
      StepNavigationButtonsWidget(goBack: widget.goBack, goNext: widget.goNext);

  void _handleKeyboardVisibility(bool value) {
    setState(() => _hideButtons = value);
  }
}
