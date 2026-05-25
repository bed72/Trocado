import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseDescriptionFieldWidget extends StatelessWidget {
  final String? failure;
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const ExpenseDescriptionFieldWidget({
    super.key,
    required this.onChanged,
    this.failure,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) => TextFieldWidget(
    hint: 'Ex: Café',
    failure: failure,
    label: 'Descrição',
    keyboardType: .name,
    onChanged: onChanged,
    initialValue: initialValue,
    textCapitalization: .sentences,
  );
}
