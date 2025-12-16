import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/calculator/presentation/stores/calculator_store.dart';
import 'package:trocado/modules/calculator/presentation/widgets/calculator_keyboard_widget.dart';

class CalculatorScreen extends StatefulWidget {
  final CalculatorStore store;

  const CalculatorScreen({super.key, required this.store});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final ReactionDisposer _disposer;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();

    _disposer = reaction<String>((_) => widget.store.expression, (value) {
      if (_controller.text == value) return;

      _controller.text = value;
    });
  }

  @override
  void dispose() {
    _disposer();

    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffoldWidget(
      title: 'Continha Rápida',
      subtitle: 'Use a calculadora pra agilizar seus registros.',
      child: Padding(
        padding: const .only(top: 12.0),
        child: Column(
          spacing: 16.0,
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            TextFieldWidget(
              label: 'R\$ 0',
              absorbing: true,
              controller: _controller,
            ),

            Observer(
              builder: (_) => Text(
                'Valor: ${widget.store.preview}',
                style: context.typography.bodyLarge?.copyWith(
                  fontWeight: .w600,
                  color: context.colors.outline,
                ),
              ),
            ),

            CalculatorKeyboard(
              onKeyTap: (key) {
                widget.store.onKeyTap(key);

                if (key == '✓') context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
