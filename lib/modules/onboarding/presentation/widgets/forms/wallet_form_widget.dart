import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';

class WalletFormWidget extends StatefulWidget {
  final bool isLoading;
  final ValueChanged<String>? onSaved;
  final VoidCallback navigateToCaculator;
  final ValueChanged<bool>? onFocusChanged;

  const WalletFormWidget({
    super.key,
    required this.isLoading,
    required this.navigateToCaculator,
    this.onSaved,
    this.onFocusChanged,
  });

  @override
  State<WalletFormWidget> createState() => _WalletFormWidgetState();
}

class _WalletFormWidgetState extends State<WalletFormWidget> {
  late bool _enabled;
  late bool _shouldShake;
  late bool _mustShowHelper;

  late final FocusNode _focus;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _enabled = false;
    _shouldShake = false;
    _mustShowHelper = false;

    _focus = FocusNode()..addListener(_handleFocus);
    _controller = TextEditingController(text: '')
      ..addListener(_handleInteractions);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_handleFocus)
      ..dispose();

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
          ShakeWidget(
            offset: 2,
            shake: _shouldShake,
            child: GestureDetector(
              onTap: widget.navigateToCaculator,
              child: TextFieldWidget(
                focus: _focus,
                absorbing: true,
                label: 'R\$ 0,0',
                inputAction: .done,
                keyboardType: .name,
                controller: _controller,
                onSubmitted: widget.onSaved,
                helperWidget: _buildAnimatedHelper(),
              ),
            ),
          ),

          _enabled ? _buildActivateButton() : _buildDeactivateButton(),
        ],
      ),
    );
  }

  AnimatedSwitcher _buildAnimatedHelper() => AnimatedSwitcher(
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    duration: const Duration(milliseconds: 300),
    transitionBuilder: (child, animation) => SizeTransition(
      axisAlignment: -1.0,
      sizeFactor: animation,
      child: child,
    ),
    child: _mustShowHelper || _shouldShake
        ? _buildHelper(
            _shouldShake
                ? 'Ops, tente novamente ou deixe para depois'
                : 'Seu nome deve conter ao menos 3 letras.',
          )
        : const SizedBox.shrink(key: ValueKey('empty')),
  );

  StepButtonWidget _buildActivateButton() => StepButtonWidget(
    label: 'Salvar apelido',
    loading: widget.isLoading,
    onTap: () => widget.onSaved?.call(_controller.text),
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

  void _handleFocus() async {
    widget.onFocusChanged?.call(_focus.hasFocus);
  }

  void _handleInteractions() {
    setState(() {
      _enabled = _controller.text.length > 2;
      _mustShowHelper =
          _controller.text.isNotEmpty && _controller.text.length < 3;
    });
  }
}
