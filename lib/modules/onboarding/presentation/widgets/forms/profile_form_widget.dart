import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/stores/onboarding_store.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';

class ProfileFormWidget extends StatefulWidget {
  final VoidCallback navigateToWallet;

  const ProfileFormWidget({super.key, required this.navigateToWallet});

  @override
  State<ProfileFormWidget> createState() => _ProfileFormWidgetState();
}

class _ProfileFormWidgetState extends State<ProfileFormWidget> {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16.0,
      children: [
        TextFieldWidget(
          inputAction: .done,
          keyboardType: .name,
          controller: _controller,
          hint: 'Seu nome ou apelido',
          helperWidget: _buildHelper(),
          onSubmitted: (_) => _handleSubimit(),
        ),

        _buildButton(),
      ],
    );
  }

  SwitcherSizeAnimation _buildHelper() => SwitcherSizeAnimation(
    child: !_mustShowHelper
        ? const SizedBox.shrink(key: ValueKey('empty'))
        : HelperWidget(title: 'Seu nome deve conter ao menos 3 letras.'),
  );

  Observer _buildButton() => Observer(
    builder: (context) {
      final store = context.get<OnboardingStore>();

      return StepButtonWidget(
        label: 'Salvar apelido',
        isLoading: store.user.isLoading,
        onTap: !_enabled ? null : () async => await _handleSubimit(),
      );
    },
  );

  void _handleInteractions() {
    setState(() {
      _enabled = _controller.text.length > 2;
      _mustShowHelper =
          _controller.text.isNotEmpty && _controller.text.length < 3;
    });
  }

  Future<void> _handleSubimit() async {
    hideKeyboard;

    final store = context.get<OnboardingStore>();

    await store.user
        .insert(UserDto(name: _controller.text, image: store.user.user.image))
        .whenComplete(widget.navigateToWallet);
  }
}
