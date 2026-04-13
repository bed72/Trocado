import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseCategoryFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const ExpenseCategoryFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: navigateTo,
      child: const TextFieldWidget(
        label: 'Categoria',
        hint: 'Categoria',
        readOnly: true,
        absorbing: true,
        // initialValue: category.label,
      ),
    );
  }
}
