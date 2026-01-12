import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/calculator/presentation/widgets/calculator_keyboard_widget.dart';

class CalculatorScreen extends StatefulWidget {
  final ValueChanged<String> amount;

  const CalculatorScreen({super.key, required this.amount});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) {},
      child: BottomSheetScaffoldWidget(
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
                hint: 'R\$',
                readOnly: true,
                absorbing: true,
                controller: _controller,
              ),

              Text(
                'Valor: ',
                style: context.typography.bodyLarge?.copyWith(
                  fontWeight: .w600,
                  color: context.colors.outline,
                ),
              ),

              CalculatorKeyboard(
                onKeyTap: (key) {
                  if (key == '✓') context.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
