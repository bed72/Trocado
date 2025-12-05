import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';

class FooterProfileWidget extends StatefulWidget {
  const FooterProfileWidget({super.key});

  @override
  State<FooterProfileWidget> createState() => _FooterProfileWidgetState();
}

class _FooterProfileWidgetState extends State<FooterProfileWidget> {
  late bool _enabled;
  late bool _mustShowHelper;

  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _enabled = false;
    _mustShowHelper = false;
    _controller = TextEditingController(text: '')
      ..addListener(_handleInteractions);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleInteractions)
      ..dispose();

    super.dispose();
  }

  void _handleInteractions() {
    setState(() {
      _enabled = _controller.text.length > 2;
      _mustShowHelper =
          _controller.text.isNotEmpty && _controller.text.length < 3;
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
          controller: _controller,
          label: 'Seu nome ou apelido',
          onSubmitted: (_) => _update(),
          helperWidget: FadeSwitchAnimation(
            type: .size,
            child: _mustShowHelper ? _buildHelper() : const SizedBox.shrink(),
          ),
        ),

        _buildButton(),
      ],
    );
  }

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

  SignalBuilder _buildButton() {
    final store = context.get<UserStore>();

    return SignalBuilder(
      builder: (_, _) => store.insert.state.when(
        ready: (data) => StepButtonWidget(
          onTap: _update,
          enabled: _enabled,
          label: 'Salvar apelido',
        ),
        error: (_, _) => StepButtonWidget(
          onTap: _update,
          enabled: _enabled,
          label: 'Salvar apelido',
        ),
        loading: () => StepButtonWidget(loading: true),
      ),
    );
  }

  void _update() {
    final store = context.get<UserStore>();

    store.resource.value = UserDto(name: _controller.text);
  }
}
