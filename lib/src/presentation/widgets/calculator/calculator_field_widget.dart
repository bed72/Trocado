import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/fields/input_widget.dart';

class CalculatorFieldWidget extends StatelessWidget {
  const CalculatorFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const InputWidget(
      label: 'Valor',
      hint: '72.0',
      readOnly: true,
      absorbing: true,
    );
  }
}
