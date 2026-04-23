import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class ExpenseSaveButtonWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSave;

  const ExpenseSaveButtonWidget({
    super.key,
    required this.onSave,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const .only(top: 16.0),
    child: ButtonWidget.outlined(
      label: 'Salvar',
      isLoading: isLoading,
      onTap: isLoading ? null : onSave,
    ),
  );
}
