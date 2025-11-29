import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';

class OnboardingStepNicknameWidget extends StatefulWidget {
  final String? source;
  final bool? isLoading;
  final VoidCallback? onEdit;
  final ValueChanged<String>? onChanged;

  const OnboardingStepNicknameWidget({
    super.key,
    this.source,
    this.onEdit,
    this.onChanged,
    this.isLoading,
  });

  @override
  State<OnboardingStepNicknameWidget> createState() =>
      _OnboardingStepNicknameWidgetState();
}

class _OnboardingStepNicknameWidgetState
    extends State<OnboardingStepNicknameWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onEdit() async {
    widget.onEdit?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.only(bottom: context.bottom + 24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              spacing: 16.0,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatar(),

                const StepTitleWidget(value: 'Como podemos te chamar?'),

                StepDescriptionWidget(
                  value:
                      'Escolha um nome ou apelido. Ele será usado para identificar você '
                      'nas suas interações e histórico dentro do Trocado.',
                  highlight: 'Trocado.',
                  highlightStyle: context.typography.bodyLarge?.copyWith(
                    height: 1.4,
                    fontWeight: .w600,
                    color: context.colors.inverseSurface.withValues(
                      alpha: 0.82,
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),

                _buildTextField(),

                StepButtonWidget(
                  label: 'Salvar apelido',
                  onTap: () {
                    widget.onChanged?.call(_controller.text);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextField _buildTextField() => TextField(
    controller: _controller,
    onChanged: widget.onChanged,
    textAlign: TextAlign.center,
    style: context.typography.bodyLarge,
    decoration: InputDecoration(
      alignLabelWithHint: true,
      hintText: 'Seu nome ou apelido',
    ),
  );

  Column _buildAvatar() => Column(
    children: [
      switch ((widget.isLoading, widget.source)) {
        (true, _) => SkeletonWidget(
          child: UserImageWidget.empty(onEdit: _onEdit),
        ),
        (_, null) => UserImageWidget.empty(onEdit: _onEdit),
        (_, final path) => UserImageWidget(
          source: path,
          onEdit: _onEdit,
          iconOnEdit: LucideIcons.pencil,
        ),
      },
    ],
  );
}
