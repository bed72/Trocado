import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';

import 'package:trocado/src/presentation/capsules/amount_capsule.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseAmountFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const ExpenseAmountFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return RearchBuilder(
      builder: (_, use) {
        final (value, _) = use(amountCapsule);

        return BounceWidget.withOnPress(
          onPress: navigateTo,
          child: TextFieldWidget(
            hint: 'Valor',
            readOnly: true,
            absorbing: true,
            initialValue: value,
            key: ValueKey(value),
            placeholder: 'Ex: 72.00',
          ),
        );
      },
    );
  }
}
