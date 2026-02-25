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
      child: TextFieldWidget(
        hint: 'Valor',
        readOnly: true,
        absorbing: true,
        placeholder: 'Ex: R\$ 1000.00',
      ),
    );
  }
}
