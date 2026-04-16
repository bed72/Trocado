import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class BudgetAmountFieldWidget extends StatelessWidget {
  final int value;
  final String? failure;
  final VoidCallback navigateTo;

  const BudgetAmountFieldWidget({
    super.key,
    required this.value,
    required this.navigateTo,
    this.failure,
  });

  String? get _displayValue => value > 0
      ? NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        ).format(value / 100)
      : null;

  @override
  Widget build(BuildContext context) => BounceWidget.withOnPress(
    onPress: navigateTo,
    child: TextFieldWidget(
      key: ValueKey(value),
      label: 'Valor',
      readOnly: true,
      absorbing: true,
      failure: failure,
      hint: 'Ex: R\$ 1.000,00',
      initialValue: _displayValue,
    ),
  );
}
