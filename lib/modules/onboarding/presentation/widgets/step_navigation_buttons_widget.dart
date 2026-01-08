import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class StepNavigationButtonsWidget extends StatelessWidget {
  final VoidCallback goBack;
  final VoidCallback goNext;

  final String? nextTitle;
  final String? backTitle;

  const StepNavigationButtonsWidget({
    super.key,
    required this.goBack,
    required this.goNext,
    this.nextTitle,
    this.backTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 16.0,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ButtonWidget.outlined(onTap: goBack, label: backTitle ?? 'Anterior'),
        ButtonWidget.elevated(
          onTap: goNext,
          child: Text(nextTitle ?? 'Próximo'),
        ),
      ],
    );
  }
}
