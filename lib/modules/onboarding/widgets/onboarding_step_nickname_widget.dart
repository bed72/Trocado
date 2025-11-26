import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/widgets/step_button_widget.dart';
import 'package:trocado/modules/onboarding/widgets/step_description_widget.dart';
import 'package:trocado/modules/onboarding/widgets/step_box_decoration_widget.dart';

class OnboardingStepNicknameWidget extends StatefulWidget {
  final String? initialValue;
  final VoidCallback onPickImage;
  final ValueChanged<String> onChanged;

  const OnboardingStepNicknameWidget({
    super.key,
    this.initialValue,
    required this.onChanged,
    required this.onPickImage,
  });

  @override
  State<OnboardingStepNicknameWidget> createState() =>
      _OnboardingStepNicknameWidgetState();
}

class _OnboardingStepNicknameWidgetState
    extends State<OnboardingStepNicknameWidget> {
  ImageProvider? _avatar;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage() async {
    widget.onPickImage();
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
                BounceWidget.withTap(
                  onTap: _handlePickImage,
                  child: StepBoxDecorationWidget(
                    width: 100,
                    height: 100,
                    child: _avatar != null
                        ? ClipOval(
                            child: Image(image: _avatar!, fit: BoxFit.cover),
                          )
                        : Icon(LucideIcons.user, size: 50.0),
                  ),
                ),

                const StepTitleWidget(value: 'Como podemos te chamar?'),

                const StepDescriptionWidget(
                  value:
                      'Escolha um nome ou apelido. Ele será usado para identificar você '
                      'nas suas interações e histórico dentro do Trocado.',
                ),

                _buildTextField(),

                StepButtonWidget(
                  onTap: () {
                    widget.onChanged(_controller.text);
                  },
                  label: 'Salvar apelido',
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
      hintText: 'Seu nome ou apelido',
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      border: OutlineInputBorder(borderRadius: context.radius.cornerRadius100),
    ),
  );
}
