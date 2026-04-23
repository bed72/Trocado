import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class CalculatorFieldWidget extends StatelessWidget {
  final String displayValue;

  const CalculatorFieldWidget({super.key, required this.displayValue});

  @override
  Widget build(BuildContext context) => TextFieldWidget(
    key: ValueKey(displayValue),
    label: 'Valor',
    readOnly: true,
    absorbing: true,
    hint: 'Ex: R\$ 1.000,00',
    initialValue: displayValue.isEmpty ? null : displayValue,
  );
}
