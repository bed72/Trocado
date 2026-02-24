import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';

import 'package:trocado/src/presentation/capsules/date_capsule.dart';
import 'package:trocado/src/presentation/extensions/date_time_extension.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseDateFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const ExpenseDateFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: navigateTo,
      child: RearchBuilder(
        builder: (_, use) {
          final (value, _) = use(dateCapsule);

          return TextFieldWidget(
            hint: 'Data',
            readOnly: true,
            absorbing: true,
            key: ValueKey(value),
            initialValue: value.format(),
          );
        },
      ),
    );
  }
}
