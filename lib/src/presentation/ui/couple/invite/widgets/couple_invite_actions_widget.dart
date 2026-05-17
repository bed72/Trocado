import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class CoupleInviteActionsWidget extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onGenerate;

  const CoupleInviteActionsWidget({
    super.key,
    required this.onScan,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12.0,
    children: [
      SizedBox(
        width: .infinity,
        child: ButtonWidget.elevated(
          onTap: onScan,
          label: 'Scanear QR code',
          child: const Icon(Icons.qr_code, size: 20.0),
        ),
      ),
      SizedBox(
        width: .infinity,
        child: ButtonWidget.outlined(
          onTap: onGenerate,
          label: 'Gerar QR code',
          child: const Icon(Icons.generating_tokens, size: 20.0),
        ),
      ),
    ],
  );
}
