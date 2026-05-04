import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class ProfileAccountActionsWidget extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onDeactivate;

  const ProfileAccountActionsWidget({
    super.key,
    required this.onDelete,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .only(top: 16.0),
    child: Row(
      spacing: 16.0,
      children: [
        Expanded(
          child: ButtonWidget.outlined(label: 'Excluir', onTap: onDelete),
        ),
        Expanded(
          child: ButtonWidget.elevated(label: 'Desativar', onTap: onDeactivate),
        ),
      ],
    ),
  );
}
