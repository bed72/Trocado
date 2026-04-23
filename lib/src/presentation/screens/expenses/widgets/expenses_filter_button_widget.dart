import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';

class ExpensesFilterButtonWidget extends StatelessWidget {
  const ExpensesFilterButtonWidget({super.key});

  @override
  Widget build(BuildContext context) => IconButtonWidget(
    width: 36.0,
    height: 36.0,
    iconSize: 18.0,
    onPress: () {},
    icon: Icons.tune_outlined,
  );
}
