import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class CalculatorFieldWidget extends StatelessWidget {
  const CalculatorFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFieldWidget(
      hint: 'Valor',
      readOnly: true,
      absorbing: true,
      placeholder: '72.0',
      initialValue: '',
      // key: ValueKey(value.hashCode),
    );
  }
}
