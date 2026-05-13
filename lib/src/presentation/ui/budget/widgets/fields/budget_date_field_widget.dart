import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class BudgetDateFieldWidget extends StatelessWidget {
  final String? failure;
  final String? displayValue;
  final VoidCallback navigateTo;

  const BudgetDateFieldWidget({
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
      readOnly: true,
      absorbing: true,
      label: 'Período',
      failure: failure,
      initialValue: displayValue,
      hint: 'Data de início e término',
    ),
  );
}
