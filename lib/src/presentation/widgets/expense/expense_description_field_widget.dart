import 'package:flutter/material.dart';

import 'package:flutter_rearch/flutter_rearch.dart';

import 'package:trocado/src/presentation/capsules/description_capsule.dart';

import 'package:trocado/src/presentation/widgets/helper_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseDescriptionFieldWidget extends StatelessWidget {
  const ExpenseDescriptionFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RearchBuilder(
      builder: (_, use) {
        final (value, setValue) = use(descriptionCapsule);

        final showHelper = value.isNotEmpty && value.length < 3;

        return TextFieldWidget(
          hint: 'Descrição',
          onChanged: setValue,
          keyboardType: .name,
          initialValue: value,
          placeholder: 'Ex: Café',
          helperWidget: showHelper
              ? const HelperWidget(
                  title: 'A descrição deve conter ao menos 3 letras.',
                )
              : null,
        );
      },
    );
  }
}
