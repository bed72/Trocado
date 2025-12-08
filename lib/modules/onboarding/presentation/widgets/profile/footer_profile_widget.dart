import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';

class FooterProfileWidget extends StatefulWidget {
  final ValueChanged<String>? onSaved;

  const FooterProfileWidget({super.key, this.onSaved});

  @override
  State<FooterProfileWidget> createState() => _FooterProfileWidgetState();
}

class _FooterProfileWidgetState extends State<FooterProfileWidget> {
  late bool _enabled;
  late bool _mustShowHelper;

  late TextEditingController _textController;
  late ButtonAnimatedController _buttonController;

  @override
  void initState() {
    super.initState();

    _enabled = false;
    _mustShowHelper = false;
    _buttonController = ButtonAnimatedController();
    _textController = TextEditingController(text: '')
      ..addListener(_handleInteractions);
  }

  @override
  void dispose() {
    _textController
      ..removeListener(_handleInteractions)
      ..dispose();

    super.dispose();
  }

  void _handleInteractions() {
    setState(() {
      _enabled = _textController.text.length > 2;
      _mustShowHelper =
          _textController.text.isNotEmpty && _textController.text.length < 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16.0,
      children: [
        TextFieldWidget(
          textAlign: .center,
          inputAction: .send,
          keyboardType: .name,
          controller: _textController,
          onSubmitted: widget.onSaved,
          label: 'Seu nome ou apelido',
          helperWidget: SwitchAnimation(
            type: .size,
            child: _mustShowHelper ? _buildHelper() : const SizedBox.shrink(),
          ),
        ),

        _enabled ? _buildActivateButton() : _buildDeactivateButton(),
      ],
    );
  }

  StepButtonWidget _buildDeactivateButton() =>
      StepButtonWidget(enabled: _enabled, label: 'Salvar apelido');

  LayoutBuilder _buildActivateButton() => LayoutBuilder(
    builder: (_, constraints) =>
        ButtonDefaultAnimatednWidget(dto: _buildDto(constraints)),
  );

  Row _buildHelper() {
    final color = context.colors.inverseSurface.withValues(alpha: 0.72);

    return Row(
      spacing: 8.0,
      children: [
        IconWidget(size: 16.0, color: color, name: LucideIcons.info),
        Text(
          'Seu nome deve conter ao menos 3 letras.',
          style: context.typography.bodyMedium?.copyWith(
            color: color,
            fontWeight: .w500,
          ),
        ),
      ],
    );
  }

  ButtonDefaultAnimatedDto _buildDto(BoxConstraints constraints) =>
      ButtonDefaultAnimatedDto(
        controller: _buttonController,
        initialWidth: constraints.maxWidth,
        initialWidget: Text(
          'Salvar apelido',
          style: context.typography.labelLarge?.copyWith(
            color: context.isDark
                ? context.colors.inverseSurface
                : context.colors.onPrimary,
          ),
        ),
        initialOnTap: () async {
          _buttonController.state(LoadingState());

          await Future.delayed(Durations.extralong4);

          _buttonController.state(SuccessState());
        },
        loadingWidget: SizedBox(
          width: 20.0,
          height: 20.0,
          child: CircularProgressIndicatorWidget(
            color: context.isDark
                ? context.colors.inverseSurface
                : context.colors.onPrimary,
          ),
        ),
        successWidget: IconWidget(
          name: LucideIcons.check,
          color: context.isDark
              ? context.colors.inverseSurface
              : context.colors.onPrimary,
        ),
        successOnTap: () async {
          await Future.delayed(
            Durations.extralong4,
            () => _buttonController.state(InitialState()),
          );
        },
        failureWidget: IconWidget(
          name: LucideIcons.info,
          color: context.isDark
              ? context.colors.inverseSurface
              : context.colors.onPrimary,
        ),
        failureOnTap: () async {
          await Future.delayed(
            Durations.extralong4,
            () => _buttonController.state(InitialState()),
          );
        },
      );
}
