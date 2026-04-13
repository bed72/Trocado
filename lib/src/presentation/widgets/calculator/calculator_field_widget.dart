import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class CalculatorFieldWidget extends StatelessWidget {
  const CalculatorFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextFieldWidget(
      label: 'Valor',
      hint: '72.0',
      readOnly: true,
      absorbing: true,
    );
  }
}
