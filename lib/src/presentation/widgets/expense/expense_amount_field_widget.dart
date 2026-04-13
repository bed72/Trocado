import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseAmountFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const ExpenseAmountFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: navigateTo,
      child: const TextFieldWidget(
        label: 'Valor',
        hint: 'Ex: R\$ 72.00',
        readOnly: true,
        absorbing: true,
      ),
    );
  }
}
