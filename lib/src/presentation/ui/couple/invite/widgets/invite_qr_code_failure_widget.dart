import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class InviteQrCodeFailureWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const InviteQrCodeFailureWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      spacing: 16.0,
      mainAxisSize: .min,
      children: [
        Icon(Icons.error_outline, size: 48.0, color: context.colors.error),
        Text(
          'Não conseguimos gerar o convite agora.',
          textAlign: .center,
          style: context.typography.bodyMedium,
        ),
        ButtonWidget.outlined(label: 'Tentar novamente', onTap: onRetry),
      ],
    ),
  );
}
