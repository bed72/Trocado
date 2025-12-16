import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';

class WalletFormWidget extends StatefulWidget {
  final bool isLoading;
  final ValueChanged<String>? onSaved;
  final VoidCallback navigateToCaculator;

  const WalletFormWidget({
    super.key,
    required this.isLoading,
    required this.navigateToCaculator,
    this.onSaved,
  });

  @override
  State<WalletFormWidget> createState() => _WalletFormWidgetState();
}

class _WalletFormWidgetState extends State<WalletFormWidget> {
  late bool _enabled;
  late bool _shouldShake;

  late final ReactionDisposer _disposer;

  late final FocusNode _amountFocus;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();

    _enabled = false;
    _shouldShake = false;

    _amountFocus = FocusNode();
    _amountController = TextEditingController()
      ..addListener(_handleInteractions);
  }

  @override
  void dispose() {
    _disposer();

    _amountFocus.dispose();

    _amountController
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
              child: _buildAmountInput(),
            ),
          ),

          _enabled ? _buildActivateButton() : _buildDeactivateButton(),
        ],
      ),
    );
  }

  StepButtonWidget _buildDeactivateButton() =>
      StepButtonWidget(label: 'Salvar carteira');

  StepButtonWidget _buildActivateButton() => StepButtonWidget(
    label: 'Salvar carteira',
    loading: widget.isLoading,
    onTap: () => widget.onSaved?.call(_amountController.text),
  );

  TextFieldWidget _buildAmountInput() => TextFieldWidget(
    absorbing: true,
    label: 'R\$ 0,0',
    inputAction: .done,
    focus: _amountFocus,
    keyboardType: .name,
    onSubmitted: widget.onSaved,
    controller: _amountController,
  );

  void _handleInteractions() {
    setState(() => _enabled = _amountController.text.length > 2);
  }
}
