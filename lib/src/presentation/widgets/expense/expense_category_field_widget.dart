import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';

import 'package:trocado/src/presentation/capsules/category_capsule.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_form_field_widget.dart';

class ExpenseCategoryFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const ExpenseCategoryFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: navigateTo,
      child: RearchBuilder(
        builder: (_, use) {
          final (selected, _) = use(categoryCapsule);

          return TextFormFieldWidget(
            readOnly: true,
            absorbing: true,
            hint: 'Categoria',
            initialValue: selected.label,
            key: ValueKey(selected.labelKey),
          );
        },
      ),
    );
  }
}
