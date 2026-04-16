import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class BudgetDescriptionFieldWidget extends StatelessWidget {
  final String? failure;
  final ValueChanged<String> onChanged;

  const BudgetDescriptionFieldWidget({
    super.key,
    required this.onChanged,
    this.failure,
  });

  @override
  Widget build(BuildContext context) => TextFieldWidget(
    failure: failure,
    label: 'Descrição',
    onChanged: onChanged,
    hint: 'Ex: Orçamento de Março',
  );
}
