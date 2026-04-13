import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/fields/input_widget.dart';

class ExpenseDescriptionFieldWidget extends StatelessWidget {
  const ExpenseDescriptionFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const InputWidget(
      label: 'Descrição',
      hint: 'Ex: Café',
      keyboardType: TextInputType.name,
    );
  }
}
