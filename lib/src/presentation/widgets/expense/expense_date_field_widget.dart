import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseDateFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const ExpenseDateFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: navigateTo,
      child: TextFieldWidget(
        hint: 'Data',
        readOnly: true,
        absorbing: true,
        // key: ValueKey(date),
        initialValue: 'date.format()',
      ),
    );
  }
}
