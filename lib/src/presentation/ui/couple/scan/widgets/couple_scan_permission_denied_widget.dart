import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class CoupleScanPermissionDeniedWidget extends StatelessWidget {
  final bool canAskAgain;
  final VoidCallback onAllow;
  final VoidCallback onManualCode;
  final VoidCallback onOpenSettings;

  const CoupleScanPermissionDeniedWidget({
    super.key,
    required this.onAllow,
    required this.canAskAgain,
    required this.onManualCode,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(16.0),
    child: Column(
      spacing: 24.0,
      crossAxisAlignment: .start,
      children: [
        const ScreenHeaderWidget(
          title: 'Câmera não disponível',
          description:
              'Precisamos da câmera para ler o QR code do convite. Você pode liberar a permissão ou digitar o código manualmente.',
        ),
        const Spacer(),
        SizedBox(
          width: .infinity,
          child: ButtonWidget.elevated(
            onTap: canAskAgain ? onAllow : onOpenSettings,
            label: canAskAgain ? 'Permitir câmera' : 'Abrir configurações',
          ),
        ),
        SizedBox(
          width: .infinity,
          child: ButtonWidget.outlined(
            onTap: onManualCode,
            label: 'Digitar código manualmente',
          ),
        ),
      ],
    ),
  );
}
