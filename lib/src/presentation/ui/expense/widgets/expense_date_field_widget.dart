import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseDateFieldWidget extends StatelessWidget {
  final String? failure;
  final String? displayValue;
  final VoidCallback navigateTo;

  const ExpenseDateFieldWidget({
    super.key,
    required this.navigateTo,
    this.failure,
    this.displayValue,
  });

  @override
  Widget build(BuildContext context) => BounceWidget.withOnPress(
    onPress: navigateTo,
    child: TextFieldWidget(
      key: ValueKey(displayValue),
      label: 'Data',
      readOnly: true,
      absorbing: true,
      failure: failure,
      hint: 'Selecione a data',
      initialValue: displayValue,
    ),
  );
}
