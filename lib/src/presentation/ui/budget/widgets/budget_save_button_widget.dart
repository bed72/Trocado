import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class BudgetSaveButtonWidget extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onSave;

  const BudgetSaveButtonWidget({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: .infinity,
    padding: const .only(top: 16.0),
    child: ButtonWidget.outlined(
      label: label,
      onTap: isLoading ? null : onSave,
      isLoading: isLoading,
    ),
  );
}
