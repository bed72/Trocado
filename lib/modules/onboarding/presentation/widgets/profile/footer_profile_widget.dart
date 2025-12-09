import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';

class FooterProfileWidget extends StatefulWidget {
  final bool didSaveData;
  final VoidCallback onFinish;
  final ValueChanged<String>? onSaved;

  const FooterProfileWidget({
    super.key,
    required this.onFinish,
    required this.didSaveData,
    this.onSaved,
  });

  @override
  State<FooterProfileWidget> createState() => _FooterProfileWidgetState();
}

class _FooterProfileWidgetState extends State<FooterProfileWidget> {
  late bool _enabled;
  late bool _shouldShake;
  late bool _mustShowHelper;

  late TextEditingController _textController;
  late ButtonAnimatedController _buttonController;

  @override
  void initState() {
    super.initState();

    _enabled = false;
    _shouldShake = false;
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
    return Padding(
      padding: const .symmetric(horizontal: 2.0),
      child: Column(
        spacing: 16.0,
        children: [
          ShakeWidget(
            offset: 2,
            shake: _shouldShake,
            child: TextFieldWidget(
              textAlign: .center,
              inputAction: .done,
              keyboardType: .name,
              controller: _textController,
              onSubmitted: widget.onSaved,
              label: 'Seu nome ou apelido',
              helperWidget: SwitchAnimation(
                type: .size,
                child: _mustShowHelper || _shouldShake
                    ? _buildHelper(
                        _shouldShake
                            ? 'Ops, tente novamente ou deixe para depois'
                            : 'Seu nome deve conter ao menos 3 letras.',
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          _enabled ? _buildActivateButton() : _buildDeactivateButton(),
        ],
      ),
    );
  }

  StepButtonWidget _buildDeactivateButton() =>
      StepButtonWidget(label: 'Salvar apelido');

  ButtonDefaultAnimatednWidget _buildActivateButton() =>
      ButtonDefaultAnimatednWidget(dto: _buildDto());

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

  ButtonDefaultAnimatedDto _buildDto() {
    final initialWidth =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    return ButtonDefaultAnimatedDto(
      initialWidth: initialWidth,
      controller: _buttonController,
      onAnimationSuccessEnd: widget.onFinish,
      initialWidget: Text(
        'Salvar apelido',
        style: context.typography.labelLarge?.copyWith(
          fontSize: 12.0,
          letterSpacing: .4,
          fontWeight: .w700,
          color: context.isDark
              ? context.colors.onPrimaryContainer
              : context.colors.onPrimary,
        ),
      ),
      initialOnTap: _handleInitialStateButton,
      loadingWidget: SizedBox(
        width: 20.0,
        height: 20.0,
        child: CircularProgressIndicatorWidget(
          color: context.isDark
              ? context.colors.onPrimaryContainer
              : context.colors.onPrimary,
        ),
      ),
      successWidget: IconWidget(
        name: LucideIcons.check,
        color: context.isDark
            ? context.colors.onPrimaryContainer
            : context.colors.onPrimary,
      ),
      failureWidget: IconWidget(
        name: LucideIcons.octagonX,
        color: context.isDark
            ? context.colors.onPrimaryContainer
            : context.colors.onPrimary,
      ),
    );
  }

  Future<void> _delayed({int milliseconds = 800, VoidCallback? action}) =>
      Future.delayed(Duration(milliseconds: milliseconds), action);

  Future<void> _handleStateButton() async {
    await _delayed(
      milliseconds: 1200,
      action: () {
        _textController.clear();
        _buttonController.state(InitialState());
      },
    );
  }

  Future<void> _handleInitialStateButton() async {
    hideKeyboard;

    widget.onSaved?.call(_textController.text);

    _buttonController.state(LoadingState());

    await _delayed();

    _buttonController.state(
      widget.didSaveData ? SuccessState() : FailureState(),
    );

    setState(() => _shouldShake = !widget.didSaveData);

    await _handleStateButton();

    setState(() => _shouldShake = false);
  }
}
