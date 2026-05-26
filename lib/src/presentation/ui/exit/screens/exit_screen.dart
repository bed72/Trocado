import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class ExitScreen extends StatelessWidget {
  final VoidCallback onExit;
  final VoidCallback onCancel;

  const ExitScreen({super.key, required this.onExit, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffoldWidget(
      title: 'Opps',
      subtitle: 'Deseja realmente sair do app?',
      child: Column(
        spacing: 16.0,
        mainAxisSize: .min,
        children: [
          const SizedBox(height: 16.0),

          Row(
            spacing: 16.0,
            children: [
              Expanded(
                child: ButtonWidget.outlined(
                  onTap: onCancel,
                  child: Text('Cancelar'),
                ),
              ),
              Expanded(
                child: ButtonWidget.danger(onTap: onExit, child: Text('Sair')),
              ),
            ],
          ),

          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
