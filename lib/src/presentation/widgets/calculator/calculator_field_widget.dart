import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';

import 'package:trocado/src/presentation/capsules/amount_capsule.dart';

import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class CalculatorFieldWidget extends StatelessWidget {
  const CalculatorFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RearchBuilder(
      builder: (_, use) {
        final (value, _) = use(amountCapsule);

        return TextFieldWidget(
          hint: 'Valor',
          readOnly: true,
          absorbing: true,
          placeholder: '72.0',
          initialValue: value,
          key: ValueKey(value.hashCode),
        );
      },
    );
  }
}
