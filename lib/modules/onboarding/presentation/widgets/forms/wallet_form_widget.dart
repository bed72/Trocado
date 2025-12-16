import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/calculator/calculator.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_button_widget.dart';

class WalletFormWidget extends StatefulWidget {
  final CalculatorStore store;

  final bool isLoading;
  final ValueChanged<String>? onSaved;
  final VoidCallback navigateToCaculator;
  final ValueChanged<bool>? onFocusChanged;

  const WalletFormWidget({
    super.key,
    required this.store,
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

  late final ReactionDisposer _disposer;

  late final FocusNode _amountFocus;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();

    _enabled = false;
    _shouldShake = false;

    _amountFocus = FocusNode()..addListener(_handleFocus);
    _amountController = TextEditingController()
      ..addListener(_handleInteractions);

    _disposer = reaction<String>((_) => widget.store.expression, (value) {
      if (_amountController.text == value) return;

      _amountController.text = value;
    });
  }

  @override
  void dispose() {
    _disposer();

    _amountFocus
      ..removeListener(_handleFocus)
      ..dispose();

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

  StepButtonWidget _buildDeactivateButton() =>
      StepButtonWidget(label: 'Salvar carteira');

  void _handleFocus() async {
    widget.onFocusChanged?.call(_amountFocus.hasFocus);
  }

  void _handleInteractions() {
    setState(() => _enabled = _amountController.text.length > 2);
  }
}
