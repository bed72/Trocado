import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class BudgetAmountFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const BudgetAmountFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: navigateTo,
      child: const TextFieldWidget(
        label: 'Valor',
        hint: 'Ex: R\$ 1000.00',
        readOnly: true,
        absorbing: true,
      ),
    );
  }
}
