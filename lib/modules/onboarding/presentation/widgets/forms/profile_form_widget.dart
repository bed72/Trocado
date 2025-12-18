import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  late bool _shouldShake;
  late bool _mustShowHelper;

  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _enabled = false;
    _shouldShake = false;
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
    return Padding(
      padding: const .symmetric(horizontal: 2.0),
      child: Column(
        spacing: 16.0,
        children: [
          ShakeAnimation(
            offset: 2,
            shake: _shouldShake,
            child: CollapseTextFormField(
              // textAlign: .center,
              inputAction: .done,
              keyboardType: .name,
              controller: _controller,
              hint: 'Seu nome ou apelido',
              // helperWidget: _buildAnimatedHelper(),
              // onSubmitted: (_) => _handleSubimit(context),
            ),
          ),

          _enabled ? _buildActivateButton() : _buildDeactivateButton(),
        ],
      ),
    );
  }

  SwicherSizeAnimation _buildAnimatedHelper() => SwicherSizeAnimation(
    child: _mustShowHelper || _shouldShake
        ? _buildHelper(
            _shouldShake
                ? 'Ops, tente novamente ou deixe para depois'
                : 'Seu nome deve conter ao menos 3 letras.',
          )
        : const SizedBox.shrink(key: ValueKey('empty')),
  );

  Observer _buildActivateButton() => Observer(
    builder: (context) {
      final store = context.get<OnboardingStore>();

      return StepButtonWidget(
        label: 'Salvar apelido',
        isLoading: store.user.isLoading,
        onTap: () async {
          await _handleSubimit(context);
        },
      );
    },
  );

  StepButtonWidget _buildDeactivateButton() =>
      StepButtonWidget(label: 'Salvar apelido');

  Row _buildHelper(String title) {
    final color = context.colors.inverseSurface.withValues(alpha: .72);

    return Row(
      spacing: 8.0,
      children: [
        IconWidget(size: 16.0, color: color, name: LucideIcons.info600),
        Text(
          title,
          style: context.typography.bodyMedium?.copyWith(
            color: color,
            fontWeight: .w600,
          ),
        ),
      ],
    );
  }

  void _handleInteractions() {
    setState(() {
      _enabled = _controller.text.length > 2;
      _mustShowHelper =
          _controller.text.isNotEmpty && _controller.text.length < 3;
    });
  }

  Future<void> _handleSubimit(BuildContext context) async {
    final store = context.get<OnboardingStore>();

    await store.user
        .insert(UserDto(name: _controller.text, image: store.user.user.image))
        .whenComplete(widget.navigateToWallet);
  }
}
