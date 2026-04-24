import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class ExpenseEditActionsWidget extends StatelessWidget {
  final bool isLoading;
  final bool isDeleting;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const ExpenseEditActionsWidget({
    super.key,
    required this.onUpdate,
    required this.onDelete,
    required this.isLoading,
    required this.isDeleting,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = isLoading || isDeleting;

    return Padding(
      padding: const .only(top: 16.0),
      child: Row(
        spacing: 16.0,
        children: [
          Expanded(
            child: ButtonWidget.outlined(
              label: 'Excluir',
              isLoading: isDeleting,
              onTap: isBusy ? null : onDelete,
            ),
          ),
          Expanded(
            child: ButtonWidget.elevated(
              label: 'Atualizar',
              isLoading: isLoading,
              onTap: isBusy ? null : onUpdate,
            ),
          ),
        ],
      ),
    );
  }
}
