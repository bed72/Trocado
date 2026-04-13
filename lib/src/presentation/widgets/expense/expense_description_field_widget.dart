import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseDescriptionFieldWidget extends StatelessWidget {
  const ExpenseDescriptionFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextFieldWidget(
      label: 'Descrição',
      hint: 'Ex: Café',
      keyboardType: TextInputType.name,
    );
  }
}
