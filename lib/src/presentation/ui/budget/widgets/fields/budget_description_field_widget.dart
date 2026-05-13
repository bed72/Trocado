import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class BudgetDescriptionFieldWidget extends StatelessWidget {
  final String hint;
  final String? failure;
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const BudgetDescriptionFieldWidget({
    super.key,
    required this.hint,
    required this.onChanged,
    this.failure,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) => TextFieldWidget(
    hint: hint,
    failure: failure,
    label: 'Descrição',
    onChanged: onChanged,
    initialValue: initialValue,
  );
}
