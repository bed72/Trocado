import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/profile/footer_profile_widget.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';

class OnboardingStepProfileWidget extends StatelessWidget {
  final String? source;
  final VoidCallback? onEdit;
  final bool? avatarIsLoading;
  final bool? nicknameIsLoading;
  final ValueChanged<String>? onSaved;

  const OnboardingStepProfileWidget({
    super.key,
    this.source,
    this.onEdit,
    this.onSaved,
    this.avatarIsLoading,
    this.nicknameIsLoading,
  });

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
              _buildAvatar(),

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

              FooterProfileWidget(onSaved: onSaved, isLoading: avatarIsLoading),
            ],
          ),
        ),
      ),
    );
  }

  void _onEdit() => onEdit?.call();

  Widget _buildAvatar() {
    return switch ((avatarIsLoading, source)) {
      (true, _) => SkeletonWidget(
        child: UserImageWidget.empty(onEdit: _onEdit),
      ),
      (_, null) => UserImageWidget.empty(onEdit: _onEdit),
      (_, final path) => UserImageWidget(
        source: path,
        onEdit: _onEdit,
        iconOnEdit: LucideIcons.pencil,
      ),
    };
  }
}
